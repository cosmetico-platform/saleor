#!/bin/bash

# Carica le chiavi RSA dai file montati
export RSA_PRIVATE_KEY=$(cat /app/keys/rsa_private_key)
export RSA_PUBLIC_KEY=$(cat /app/keys/rsa_public_key)

# Esegui il comando passato come argomento
exec "$@"
