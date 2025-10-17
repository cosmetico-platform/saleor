#!/bin/bash
set -e

echo "🚀 Setup Saleor - Configurazione Completa"
echo "=========================================="

# Funzione per generare chiavi sicure
generate_secrets() {
    echo "🔐 Generazione chiavi sicure..."
    
    # Crea directory secrets se non esiste
    mkdir -p secrets
    
    # Pulisce eventuali file esistenti
    echo "🧹 Pulizia file esistenti..."
    rm -f secrets/jwt_rsa secrets/jwt_rsa.pub secrets/secret_key.txt secrets/admin_password.txt secrets/database_password.txt
    
    # Genera SECRET_KEY sicura
    echo "📝 Generando SECRET_KEY..."
    openssl rand -base64 50 > secrets/secret_key.txt
    
    # Genera chiavi JWT in formato PEM
    echo "🔑 Generando chiavi JWT in formato PEM..."
    openssl genrsa -out secrets/jwt_rsa 4096
    openssl rsa -in secrets/jwt_rsa -pubout -out secrets/jwt_rsa.pub
    
    # Genera password sicure
    echo "👤 Generando password admin..."
    openssl rand -base64 32 > secrets/admin_password.txt
    
    echo "🗄️ Generando password database..."
    openssl rand -base64 24 > secrets/database_password.txt
    
    # Imposta permessi sicuri
    chmod 600 secrets/*
    chmod 700 secrets/
    
    # Verifica chiavi generate
    echo "🔍 Verifica chiavi generate..."
    if [ ! -f "secrets/jwt_rsa" ] || [ ! -f "secrets/jwt_rsa.pub" ]; then
        echo "❌ Errore: Chiavi JWT non generate correttamente"
        exit 1
    fi
    
    if ! head -1 secrets/jwt_rsa | grep -q "BEGIN.*PRIVATE KEY"; then
        echo "❌ Errore: Chiave privata non in formato PEM"
        exit 1
    fi
    
    if ! head -1 secrets/jwt_rsa.pub | grep -q "BEGIN PUBLIC KEY"; then
        echo "❌ Errore: Chiave pubblica non in formato PEM"
        exit 1
    fi
    
    echo "✅ Chiavi generate con successo!"
}

# Funzione per caricare variabili d'ambiente
load_environment() {
    echo "🔧 Caricamento variabili d'ambiente..."
    
    # Crea file .env con variabili espanse
    cat > .env << EOF
# Saleor Production Environment Variables
# Generated automatically - DO NOT COMMIT TO GIT

# Database
DATABASE_URL=postgres://saleor:$(cat secrets/database_password.txt)@db:5432/saleor
DB_PASSWORD=$(cat secrets/database_password.txt)

# Celery
CELERY_BROKER_URL=redis://redis:6379/1

# Email
DEFAULT_FROM_EMAIL=noreply@vitoesposito.it
EMAIL_URL=smtp://localhost:1025

# Security (generati automaticamente)
SECRET_KEY=$(cat secrets/secret_key.txt)
HTTP_IP_FILTER_ALLOW_LOOPBACK_IPS=False

# Dashboard
DASHBOARD_URL=https://dashboard.vitoesposito.it/

# CORS Configuration
ALLOWED_GRAPHQL_ORIGINS=https://dashboard.vitoesposito.it,https://vitoesposito.it,https://api.vitoesposito.it,https://saleor-api.vitoesposito.it,https://cms.vitoesposito.it,https://storage.vitoesposito.it,https://mailpit.vitoesposito.it
ALLOWED_HOSTS=saleor-api.vitoesposito.it,localhost,127.0.0.1
ALLOWED_CLIENT_HOSTS=saleor-api.vitoesposito.it,dashboard.vitoesposito.it,vitoesposito.it,api.vitoesposito.it,cms.vitoesposito.it,storage.vitoesposito.it,mailpit.vitoesposito.it

# Production settings
DEBUG=False
INTERNAL_IPS=127.0.0.1
PLAYGROUND_ENABLED=False

# Admin Configuration
ADMIN_EMAIL=dev@vitoesposito.it
ADMIN_PASSWORD=$(cat secrets/admin_password.txt)
ADMIN_FIRST_NAME=Default
ADMIN_LAST_NAME=admin

# JWT Keys (caricate automaticamente da secrets/)
# RSA_PRIVATE_KEY e RSA_PUBLIC_KEY sono caricate dai file secrets/
EOF
    
    echo "✅ Variabili d'ambiente caricate con successo!"
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
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Redis: localhost:6379"
    echo ""
    echo "👤 Credenziali Admin:"
    echo "  - Email: dev@vitoesposito.it"
    echo "  - Password: $(cat secrets/admin_password.txt)"
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
    "setup"|"")
        echo "🔄 Setup completo..."
        generate_secrets
        load_environment
        start_services
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
        echo "  setup    - Setup completo (default)"
        echo "  secrets  - Genera solo le chiavi sicure"
        echo "  env      - Carica solo le variabili d'ambiente"
        echo "  start    - Avvia solo i servizi Docker"
        echo "  help     - Mostra questo aiuto"
        ;;
    *)
        echo "❌ Comando sconosciuto: $1"
        echo "Usa '$0 help' per vedere i comandi disponibili"
        exit 1
        ;;
esac
