# 🔐 Gestione Secrets - GitHub Organization

## 🎯 Strategia per l'Organizzazione

### 1. **GitHub Organization Secrets**
Configura questi secrets nell'organizzazione GitHub:

#### Secrets di Produzione
```
SALEOR_SECRET_KEY
SALEOR_ADMIN_PASSWORD  
SALEOR_DB_PASSWORD
SALEOR_JWT_PRIVATE_KEY
SALEOR_JWT_PUBLIC_KEY
```

#### Secrets di Staging
```
SALEOR_STAGING_SECRET_KEY
SALEOR_STAGING_ADMIN_PASSWORD
SALEOR_STAGING_DB_PASSWORD
SALEOR_STAGING_JWT_PRIVATE_KEY
SALEOR_STAGING_JWT_PUBLIC_KEY
```

### 2. **Workflow per Nuovi Sviluppatori**

#### Onboarding Automatico
```bash
# Nuovo sviluppatore clona il repo
git clone https://github.com/your-org/saleor-cosmetico.git
cd saleor-cosmetico

# Setup automatico
./scripts/onboard-dev.sh
```

#### Setup Manuale (se necessario)
```bash
# Genera secrets locali
./scripts/setup.sh secrets

# Carica variabili d'ambiente
./scripts/setup.sh env

# Avvia servizi
./scripts/setup.sh start
```

### 3. **Gestione per Ambiente**

#### Sviluppo Locale
- ✅ Secrets generati automaticamente
- ✅ File locali in `secrets/`
- ✅ Ignorati da Git

#### Staging/Produzione
- ✅ Secrets da GitHub Organization
- ✅ Iniettati via CI/CD
- ✅ Mai committati nel repo

### 4. **Workflow CI/CD**

#### Deploy Staging
```yaml
- name: Setup Staging Secrets
  run: |
    mkdir -p secrets
    echo "${{ secrets.SALEOR_STAGING_SECRET_KEY }}" > secrets/secret_key.txt
    echo "${{ secrets.SALEOR_STAGING_ADMIN_PASSWORD }}" > secrets/admin_password.txt
    # ... altri secrets
```

#### Deploy Produzione
```yaml
- name: Setup Production Secrets
  run: |
    mkdir -p secrets
    echo "${{ secrets.SALEOR_SECRET_KEY }}" > secrets/secret_key.txt
    echo "${{ secrets.SALEOR_ADMIN_PASSWORD }}" > secrets/admin_password.txt
    # ... altri secrets
```

## 🔧 Configurazione GitHub Organization

### 1. Vai su GitHub Organization
- Settings → Secrets and variables → Actions
- Aggiungi i secrets elencati sopra

### 2. Configura Repository Secrets
- Settings → Secrets and variables → Actions
- Aggiungi secrets specifici del repository

### 3. Configura Environment Secrets
- Settings → Environments
- Crea environments: `staging`, `production`
- Aggiungi secrets specifici per ambiente

## 📋 Checklist per Nuovi Sviluppatori

- [ ] Clona il repository
- [ ] Esegui `./scripts/onboard-dev.sh`
- [ ] Verifica che i servizi siano attivi
- [ ] Leggi `DEVELOPMENT.md`
- [ ] Configura il tuo ambiente locale
- [ ] Testa l'accesso al dashboard

## 🚨 Regole di Sicurezza

### ❌ NON Fare Mai
- Committare file in `secrets/`
- Condividere secrets via chat/email
- Hardcodare secrets nel codice
- Usare secrets di produzione in sviluppo

### ✅ Fare Sempre
- Usare `./scripts/setup.sh` per generare secrets
- Mantenere secrets locali separati
- Usare GitHub Secrets per CI/CD
- Fare backup sicuro dei secrets di produzione

## 🔄 Aggiornamento Secrets

### Per Sviluppatori
```bash
# Rigenera secrets locali
./scripts/setup.sh secrets
./scripts/setup.sh env
docker compose restart
```

### Per Amministratori
1. Aggiorna secrets in GitHub Organization
2. Notifica il team del cambio
3. Aggiorna documentazione se necessario

## 📞 Supporto

- **Issues**: GitHub Issues
- **Documentazione**: `DEVELOPMENT.md`
- **Admin**: admin@vitoesposito.it
