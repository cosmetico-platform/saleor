# Scripts Saleor

## 🚀 Setup Principale

### `setup.sh` - Script Unificato

Script principale che gestisce tutto il setup di Saleor con MinIO integrato.

#### Comandi Disponibili

```bash
# Setup completo (default)
./scripts/setup.sh

# Comandi specifici
./scripts/setup.sh secrets      # Genera solo le chiavi sicure
./scripts/setup.sh env          # Carica solo le variabili d'ambiente
./scripts/setup.sh start        # Avvia solo i servizi Docker
./scripts/setup.sh init-minio   # Inizializza MinIO
./scripts/setup.sh dev          # Avvia in modalità development
./scripts/setup.sh help         # Mostra aiuto
```

#### Funzionalità Integrate

- ✅ **Generazione Chiavi Sicure**: JWT, password, secret key
- ✅ **Configurazione Ambiente**: Variabili d'ambiente automatiche
- ✅ **Gestione MinIO**: Inizializzazione e test automatici
- ✅ **Avvio Servizi**: Docker Compose integrato
- ✅ **Modalità Development**: Setup semplificato per sviluppo

## 🔧 Altri Script

### `load-keys.sh`
Script per caricare le chiavi JWT nei container Docker.

### `init-smart.sh`
Script per inizializzazione intelligente del database.

### `onboard-dev.sh`
Script per onboarding sviluppatori.

## 📋 Workflow Tipico

### Setup Iniziale
```bash
cd /home/vito/cosmetico/saleor
./scripts/setup.sh
```

### Sviluppo
```bash
./scripts/setup.sh dev
```


## 🎯 Vantaggi della Nuova Struttura

1. **Unificazione**: Un solo script per tutto
2. **Semplicità**: Meno file da gestire
3. **Manutenibilità**: Codice centralizzato
4. **Flessibilità**: Comandi specifici quando necessario
5. **Integrazione**: MinIO completamente integrato

## 🔍 Troubleshooting

### MinIO non si inizializza
```bash
./scripts/setup.sh init-minio
```


### Reset completo
```bash
docker compose down -v
./scripts/setup.sh
```