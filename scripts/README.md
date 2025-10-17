# 🔧 Scripts Saleor

## 📋 Struttura Script

### `setup.sh` - Script Principale
**Script unificato per la gestione completa di Saleor**

```bash
./scripts/setup.sh [comando]
```

**Comandi disponibili:**
- `setup` (default) - Setup completo: genera chiavi, carica env, avvia servizi
- `secrets` - Genera solo le chiavi sicure (JWT, SECRET_KEY, password)
- `env` - Carica solo le variabili d'ambiente nel file .env
- `start` - Avvia solo i servizi Docker
- `help` - Mostra l'aiuto

**Esempi:**
```bash
# Setup completo
./scripts/setup.sh

# Solo generazione chiavi
./scripts/setup.sh secrets

# Solo caricamento variabili
./scripts/setup.sh env

# Solo avvio servizi
./scripts/setup.sh start
```

### `load-keys.sh` - Caricamento Chiavi JWT
**Script utilizzato da Docker per caricare le chiavi JWT**

- Legge le chiavi dai file montati in `/app/keys/`
- Le esporta come variabili d'ambiente `RSA_PRIVATE_KEY` e `RSA_PUBLIC_KEY`
- Utilizzato automaticamente da `docker-compose.yml`

### `init-smart.sh` - Inizializzazione Saleor
**Script di inizializzazione intelligente per i container**

- Esegue migrazioni database
- Raccoglie file statici
- Crea superuser solo al primo avvio
- Avvia il server Uvicorn

## 🔄 Workflow Tipico

### Setup Iniziale
```bash
./scripts/setup.sh
```

### Aggiornamento Configurazioni
```bash
./scripts/setup.sh env
docker compose restart
```

### Rigenerazione Chiavi
```bash
./scripts/setup.sh secrets
./scripts/setup.sh env
docker compose restart
```

### Solo Riavvio Servizi
```bash
./scripts/setup.sh start
```

## 🔒 Sicurezza

- Tutte le chiavi sono generate in formato PEM
- Password sicure generate con `openssl rand`
- File sensibili con permessi 600
- Directory `secrets/` ignorata da Git

## 📁 File Generati

### Directory `secrets/`
- `jwt_rsa` - Chiave privata JWT (PEM)
- `jwt_rsa.pub` - Chiave pubblica JWT (PEM)
- `secret_key.txt` - SECRET_KEY Django
- `admin_password.txt` - Password admin
- `database_password.txt` - Password database

### File `.env`
- Variabili d'ambiente complete per produzione
- Valori sicuri espansi dai file secrets/
- Configurazione CORS per i domini
