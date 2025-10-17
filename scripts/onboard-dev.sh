#!/bin/bash
set -e

echo "👋 Benvenuto nel progetto Saleor Cosmetico!"
echo "============================================="

# Verifica prerequisiti
echo "🔍 Verificando prerequisiti..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker non trovato. Installa Docker prima di continuare."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose non trovato. Installa Docker Compose prima di continuare."
    exit 1
fi

if ! command -v openssl &> /dev/null; then
    echo "❌ OpenSSL non trovato. Installa OpenSSL prima di continuare."
    exit 1
fi

echo "✅ Prerequisiti verificati!"

# Verifica se secrets esistono già
if [ -d "secrets" ] && [ -f ".env" ]; then
    echo "⚠️  Secrets già esistenti trovati."
    read -p "Vuoi rigenerarli? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 Rigenerando secrets..."
        rm -rf secrets/ .env
    else
        echo "ℹ️  Mantenendo secrets esistenti."
        exit 0
    fi
fi

# Setup completo
echo "🚀 Avviando setup completo..."
./scripts/setup.sh

# Verifica setup
echo "🔍 Verificando setup..."
if docker compose ps | grep -q "Up"; then
    echo "✅ Setup completato con successo!"
    echo ""
    echo "🌐 Servizi disponibili:"
    echo "  - Saleor API: http://localhost:8000"
    echo "  - Dashboard: http://localhost:9000"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Redis: localhost:6379"
    echo ""
    echo "👤 Credenziali Admin:"
    echo "  - Email: admin@vitoesposito.it"
    echo "  - Password: $(cat secrets/admin_password.txt)"
    echo ""
    echo "📋 Prossimi passi:"
    echo "  1. Leggi DEVELOPMENT.md per la documentazione completa"
    echo "  2. Accedi al dashboard per configurare il tuo store"
    echo "  3. Fai backup sicuro della directory secrets/"
    echo ""
    echo "🎉 Benvenuto nel team!"
else
    echo "❌ Errore durante il setup. Controlla i log:"
    echo "   docker compose logs"
    exit 1
fi
