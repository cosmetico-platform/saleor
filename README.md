# Saleor E-commerce Platform

Configurazione personalizzata di Saleor per produzione.

## 🚀 Quick Start

### Setup Iniziale
```bash
# Setup completo con un comando
./scripts/setup.sh

# Oppure step by step:
./scripts/setup.sh secrets  # Genera chiavi sicure
./scripts/setup.sh env      # Carica variabili d'ambiente  
./scripts/setup.sh start    # Avvia servizi Docker
```

### Accesso
- **Dashboard**: https://dashboard.vitoesposito.it
- **API GraphQL**: https://saleor-api.vitoesposito.it/graphql/
- **Admin**: admin@vitoesposito.it (password in secrets/)

## 📁 Struttura

```
├── secrets/           # 🔒 Configurazioni sicure
├── scripts/           # 🔧 Script di gestione
├── saleor/           # 📦 Codice Saleor
├── templates/        # 🎨 Template personalizzati
├── docker-compose.yml # 🐳 Configurazione servizi
└── Dockerfile        # 🐳 Immagine personalizzata
```

## 🔧 Gestione

### Aggiornare configurazioni
```bash
./scripts/setup.sh env
docker compose restart
```

### Backup
```bash
# Backup solo directory secrets/
tar -czf saleor-backup-$(date +%Y%m%d).tar.gz secrets/
```

### Logs
```bash
docker compose logs -f saleor
docker compose logs -f celery
```

## 🔒 Sicurezza

- Chiavi JWT dedicate
- Password sicure generate automaticamente
- Database accessibile solo internamente
- File sensibili ignorati da Git

## 📞 Supporto

Per problemi o modifiche, contattare l'amministratore di sistema.