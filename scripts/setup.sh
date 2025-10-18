#!/bin/bash
set -e

# Ottieni la directory dello script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_DIR="$PROJECT_ROOT/secrets"

echo "🚀 Setup Saleor - Configurazione Completa"
echo "=========================================="

# Funzione per generare chiavi sicure
generate_secrets() {
    echo "🔐 Generazione chiavi sicure..."
    
    # Crea directory secrets se non esiste
    mkdir -p "$SECRETS_DIR"
    
    # Pulisce eventuali file esistenti
    echo "🧹 Pulizia file esistenti..."
    rm -f "$SECRETS_DIR/jwt_rsa" "$SECRETS_DIR/jwt_rsa.pub" "$SECRETS_DIR/secret_key.txt" "$SECRETS_DIR/admin_password.txt" "$SECRETS_DIR/database_password.txt" "$SECRETS_DIR/minio_password.txt"
    
    # Genera SECRET_KEY sicura
    echo "📝 Generando SECRET_KEY..."
    openssl rand -base64 50 | tr -d '\n' > "$SECRETS_DIR/secret_key.txt"
    
    # Genera chiavi JWT in formato PEM
    echo "🔑 Generando chiavi JWT in formato PEM..."
    openssl genrsa -out "$SECRETS_DIR/jwt_rsa" 4096
    openssl rsa -in "$SECRETS_DIR/jwt_rsa" -pubout -out "$SECRETS_DIR/jwt_rsa.pub"
    
    # Genera password sicure
    echo "👤 Generando password admin..."
    openssl rand -base64 32 | tr -d '\n' > "$SECRETS_DIR/admin_password.txt"
    
    echo "🗄️ Generando password database..."
    openssl rand -base64 24 | tr -d '\n' | tr -d '+' | tr -d '/' | tr -d '=' > "$SECRETS_DIR/database_password.txt"
    
    echo "🗄️ Generando password MinIO..."
    openssl rand -base64 32 | tr -d '\n' > "$SECRETS_DIR/minio_password.txt"
    
    # Imposta permessi per Docker container
    chmod 644 "$SECRETS_DIR"/*
    chmod 755 "$SECRETS_DIR"
    
    # Verifica chiavi generate
    echo "🔍 Verifica chiavi generate..."
    if [ ! -f "$SECRETS_DIR/jwt_rsa" ] || [ ! -f "$SECRETS_DIR/jwt_rsa.pub" ]; then
        echo "❌ Errore: Chiavi JWT non generate correttamente"
        exit 1
    fi
    
    if ! head -1 "$SECRETS_DIR/jwt_rsa" | grep -q "BEGIN.*PRIVATE KEY"; then
        echo "❌ Errore: Chiave privata non in formato PEM"
        exit 1
    fi
    
    if ! head -1 "$SECRETS_DIR/jwt_rsa.pub" | grep -q "BEGIN PUBLIC KEY"; then
        echo "❌ Errore: Chiave pubblica non in formato PEM"
        exit 1
    fi
    
    echo "✅ Chiavi generate con successo!"
}

# Funzione per caricare variabili d'ambiente
load_environment() {
    echo "🔧 Caricamento variabili d'ambiente..."
    
    # Crea file .env con variabili espanse nella root del progetto
    cat > "$PROJECT_ROOT/.env" << EOF
# Saleor Production Environment Variables
# Generated automatically - DO NOT COMMIT TO GIT

# Database
DATABASE_URL=postgres://saleor:$(cat "$SECRETS_DIR/database_password.txt")@db:5432/saleor
DB_PASSWORD=$(cat "$SECRETS_DIR/database_password.txt")

# Celery
CELERY_BROKER_URL=redis://redis:6379/1

# Email
DEFAULT_FROM_EMAIL=noreply@vitoesposito.it
EMAIL_URL=smtp://localhost:1025

# Security (generati automaticamente)
SECRET_KEY=$(cat "$SECRETS_DIR/secret_key.txt")
HTTP_IP_FILTER_ALLOW_LOOPBACK_IPS=False

# Dashboard
DASHBOARD_URL=https://dashboard.vitoesposito.it/
API_URL=https://saleor-api.vitoesposito.it/graphql/

# CORS Configuration
ALLOWED_HOSTS=saleor-api.vitoesposito.it,localhost,127.0.0.1
ALLOWED_CLIENT_HOSTS=saleor-api.vitoesposito.it,dashboard.vitoesposito.it,vitoesposito.it,api.vitoesposito.it,cms.vitoesposito.it,storage.vitoesposito.it,mailpit.vitoesposito.it

# Production settings
DEBUG=False
INTERNAL_IPS=127.0.0.1
PLAYGROUND_ENABLED=False

# Admin Configuration
ADMIN_EMAIL=dev@vitoesposito.it
ADMIN_PASSWORD=$(cat "$SECRETS_DIR/admin_password.txt")
ADMIN_FIRST_NAME=Default
ADMIN_LAST_NAME=admin

# MinIO Object Storage
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=$(cat "$SECRETS_DIR/minio_password.txt")
MINIO_ENDPOINT=https://minio-api.vitoesposito.it
MINIO_PORT=9001
MINIO_USE_SSL=True
MINIO_ACCESS_KEY=admin
MINIO_SECRET_KEY=$(cat "$SECRETS_DIR/minio_password.txt")
MINIO_MEDIA_BUCKET_NAME=saleor-media
MINIO_MEDIA_CUSTOM_DOMAIN=https://storage.vitoesposito.it

# JWT Keys (caricate automaticamente da secrets/)
# RSA_PRIVATE_KEY e RSA_PUBLIC_KEY sono caricate dai file secrets/
EOF
    
    echo "✅ Variabili d'ambiente caricate con successo!"
    echo "📁 File .env creato in: $PROJECT_ROOT/.env"
}


# Funzione per inizializzare MinIO
init_minio() {
    echo "🪣 Inizializzazione MinIO..."
    
    # Attendi che MinIO sia pronto
    echo "⏳ Attesa che MinIO sia pronto..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -f http://localhost:9001/minio/health/live >/dev/null 2>&1; then
            echo "✅ MinIO è pronto!"
            break
        fi
        echo "MinIO non ancora pronto, attesa... ($((attempt + 1))/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -eq $max_attempts ]; then
        echo "❌ MinIO non è diventato pronto dopo $max_attempts tentativi"
        return 1
    fi
    
    # Crea il bucket usando Docker exec
    echo "📦 Creazione bucket 'saleor-media'..."
    docker compose exec -T minio sh -c "
        mc alias set local http://localhost:9000 admin $(cat "$SECRETS_DIR/minio_password.txt") &&
        mc mb local/saleor-media --ignore-existing &&
        mc anonymous set public local/saleor-media
    " 2>/dev/null || {
        echo "⚠️ Bucket potrebbe essere già esistente o errore di configurazione"
    }
    
    echo "✅ MinIO inizializzato!"
}


# Funzione per avviare i servizi
start_services() {
    echo "🐳 Avvio servizi Docker..."
    
    # Ferma servizi esistenti
    docker compose down 2>/dev/null || true
    
    # Avvia servizi
    docker compose up -d
    
    echo "✅ Servizi avviati con successo!"
    echo ""
    echo "🌐 Servizi disponibili:"
    echo "  - Saleor API: http://localhost:8000"
    echo "  - Dashboard: http://localhost:9000"
    echo "  - MinIO API: http://localhost:9001"
    echo "  - MinIO Console: http://localhost:9002"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Redis: localhost:6379"
    echo ""
    echo "👤 Credenziali Admin:"
    echo "  - Email: dev@vitoesposito.it"
    echo "  - Password: $(cat "$SECRETS_DIR/admin_password.txt")"
    echo ""
    echo "📦 Credenziali MinIO:"
    echo "  - Username: admin"
    echo "  - Password: $(cat "$SECRETS_DIR/minio_password.txt")"
    echo "  - Console: https://storage.vitoesposito.it:9002"
}

# Funzione per avviare in modalità development
start_dev() {
    echo "🛠️ Avvio in modalità development..."
    
    # Carica variabili d'ambiente per development
    load_environment
    
    # Avvia solo i servizi di supporto
    echo "🐳 Avvio servizi di supporto..."
    docker compose up -d db redis minio
    
    # Attendi che i servizi siano pronti
    echo "⏳ Attesa servizi di supporto..."
    sleep 10
    
    # Inizializza MinIO
    init_minio
    
    
    echo "✅ Modalità development pronta!"
    echo "🚀 Avvia Saleor con: python manage.py runserver"
}

# Menu principale
case "${1:-setup}" in
    "secrets")
        generate_secrets
        ;;
    "env")
        load_environment
        ;;
    "start")
        start_services
        ;;
    "init-minio")
        init_minio
        ;;
    "dev")
        start_dev
        ;;
    "setup"|"")
        echo "🔄 Setup completo..."
        generate_secrets
        load_environment
        start_services
        
        # Attendi che i servizi siano pronti
        echo "⏳ Attesa servizi..."
        sleep 30
        
        # Inizializza MinIO
        init_minio
        
        
        echo ""
        echo "🎉 Setup completato con successo!"
        echo "📋 Prossimi passi:"
        echo "  1. Accedi al dashboard: https://dashboard.vitoesposito.it"
        echo "  2. Configura il tuo store"
        echo "  3. Fai backup della directory secrets/"
        ;;
    "help")
        echo "Uso: $0 [comando]"
        echo ""
        echo "Comandi:"
        echo "  setup        - Setup completo (default)"
        echo "  secrets      - Genera solo le chiavi sicure"
        echo "  env          - Carica solo le variabili d'ambiente"
        echo "  start        - Avvia solo i servizi Docker"
        echo "  init-minio   - Inizializza MinIO"
        echo "  dev          - Avvia in modalità development"
        echo "  help         - Mostra questo aiuto"
        ;;
    *)
        echo "❌ Comando sconosciuto: $1"
        echo "Usa '$0 help' per vedere i comandi disponibili"
        exit 1
        ;;
esac