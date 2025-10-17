# 🚀 Guida per Sviluppatori

## 📋 Setup Iniziale

### 1. Clone del Repository
```bash
git clone https://github.com/your-org/saleor-cosmetico.git
cd saleor-cosmetico
```

### 2. Generazione Secrets
```bash
# Opzione A: Script automatico (raccomandato)
./scripts/setup.sh

# Opzione B: Setup manuale
./scripts/setup.sh secrets
./scripts/setup.sh env
./scripts/setup.sh start
```

### 3. Verifica Setup
```bash
# Controlla che i servizi siano attivi
docker compose ps

# Controlla i log
docker compose logs saleor --tail=20
```

## 🔐 Gestione Secrets

### Struttura Directory Secrets
```
secrets/
├── jwt_rsa              # Chiave privata JWT (PEM)
├── jwt_rsa.pub          # Chiave pubblica JWT (PEM)
├── secret_key.txt       # SECRET_KEY Django
├── admin_password.txt   # Password admin
└── database_password.txt # Password database
```

### Regole Importanti
- ❌ **NON committare** mai la directory `secrets/`
- ❌ **NON condividere** i file secrets via chat/email
- ✅ **Usa sempre** `./scripts/setup.sh` per generare nuovi secrets
- ✅ **Fai backup** sicuro dei secrets in produzione

## 🌐 Configurazione Domini

### Domini di Produzione
- **API**: `saleor-api.vitoesposito.it`
- **Dashboard**: `dashboard.vitoesposito.it`
- **CMS**: `cms.vitoesposito.it`
- **Storage**: `storage.vitoesposito.it`

### Domini di Sviluppo
- **API**: `localhost:8000`
- **Dashboard**: `localhost:9000`

## 🔧 Comandi Utili

### Gestione Servizi
```bash
# Avvio completo
./scripts/setup.sh

# Solo riavvio servizi
./scripts/setup.sh start

# Solo aggiornamento env
./scripts/setup.sh env

# Solo rigenerazione secrets
./scripts/setup.sh secrets
```

### Debug
```bash
# Logs in tempo reale
docker compose logs -f saleor

# Accesso al container
docker compose exec saleor bash

# Reset completo
docker compose down -v
rm -rf secrets/ .env
./scripts/setup.sh
```

## 🚨 Troubleshooting

### Problemi Comuni

**Errore JWT:**
```bash
# Rigenera le chiavi
./scripts/setup.sh secrets
docker compose restart
```

**Errore Database:**
```bash
# Reset database
docker compose down -v
./scripts/setup.sh
```

**Errore CORS:**
```bash
# Verifica configurazione domini
cat .env | grep ALLOWED
```

## 📞 Supporto

- **Documentazione**: `scripts/README.md`
- **Issues**: GitHub Issues
- **Admin**: admin@vitoesposito.it

## 🔒 Sicurezza

- Tutti i secrets sono generati automaticamente
- Password sicure con `openssl rand`
- Chiavi JWT in formato PEM
- File con permessi 600
- Directory ignorata da Git
