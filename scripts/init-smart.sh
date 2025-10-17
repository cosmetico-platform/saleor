#!/bin/bash
set -e

echo "🚀 Inizializzazione Saleor..."

# Controlla se è la prima esecuzione
FIRST_RUN_FILE="/app/.first_run_complete"

# Esegui migrazioni (sempre necessarie)
echo "📊 Eseguendo migrazioni database..."
python manage.py migrate

# Raccogli file statici (sempre necessario)
echo "📁 Raccogliendo file statici..."
python manage.py collectstatic --noinput

# Inizializzazione solo al primo avvio
if [ ! -f "$FIRST_RUN_FILE" ]; then
    echo "🎯 Prima esecuzione - Inizializzazione completa..."
    
    # Crea superuser
    echo "👤 Creando superuser..."
    python manage.py shell << EOF
import os
from django.contrib.auth import get_user_model
User = get_user_model()

admin_email = os.getenv('ADMIN_EMAIL', 'admin@vitoesposito.it')
admin_password = os.getenv('ADMIN_PASSWORD', 'admin123')
admin_first_name = os.getenv('ADMIN_FIRST_NAME', 'Admin')
admin_last_name = os.getenv('ADMIN_LAST_NAME', 'Vito')

if not User.objects.filter(email=admin_email).exists():
    User.objects.create_superuser(
        email=admin_email,
        password=admin_password,
        first_name=admin_first_name,
        last_name=admin_last_name
    )
    print(f"✅ Superuser creato: {admin_email} / {admin_password}")
else:
    print("ℹ️  Superuser già esistente")
EOF

    # Marca come completato
    touch "$FIRST_RUN_FILE"
    echo "✅ Inizializzazione completata!"
else
    echo "ℹ️  Inizializzazione già completata, avvio diretto..."
fi

# Avvia il server
echo "🌐 Avviando server Saleor..."
exec uvicorn saleor.asgi:application \
    --host=0.0.0.0 \
    --port=8000 \
    --workers=2 \
    --lifespan=off \
    --ws=none \
    --no-server-header \
    --no-access-log \
    --timeout-keep-alive=35 \
    --timeout-graceful-shutdown=30 \
    --limit-max-requests=10000
