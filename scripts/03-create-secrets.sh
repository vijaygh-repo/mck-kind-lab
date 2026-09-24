#!/usr/bin/env bash
# 03-create-secrets.sh
# Creates the Ops Manager admin bootstrap credentials secret (idempotent).
set -euo pipefail

NAMESPACE="mongodb"
SECRET_NAME="ops-manager-admin"

log() { echo -e "\033[1;32m[secrets]\033[0m $*"; }

OM_USERNAME="${OM_USERNAME:-admin@example.com}"
OM_PASSWORD="${OM_PASSWORD:-$(openssl rand -base64 18)Aa1!}"

if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
  log "Secret '$SECRET_NAME' already exists, leaving it untouched."
else
  kubectl create secret generic "$SECRET_NAME" \
    --namespace "$NAMESPACE" \
    --from-literal=Username="$OM_USERNAME" \
    --from-literal=Password="$OM_PASSWORD" \
    --from-literal=FirstName="Ops" \
    --from-literal=LastName="Admin"
  log "Created secret '$SECRET_NAME'."
  log "Username: $OM_USERNAME"
  log "Password: $OM_PASSWORD  (save this - needed to log into the Ops Manager UI)"
fi
