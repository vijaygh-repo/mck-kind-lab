#!/usr/bin/env bash
# 08-deploy-search.sh
# Creates the search sync user (searchCoordinator role) and the MongoDBSearch (mongot) resource.
set -euo pipefail
cd "$(dirname "$0")/.."

NAMESPACE="mongodb"

log() { echo -e "\033[1;32m[search]\033[0m $*"; }

if kubectl get secret search-sync-source-password -n "$NAMESPACE" >/dev/null 2>&1; then
  log "Secret 'search-sync-source-password' already exists, leaving it untouched."
else
  kubectl create secret generic search-sync-source-password \
    --namespace "$NAMESPACE" \
    --from-literal=password="$(openssl rand -base64 24)"
fi

kubectl apply -f manifests/05-search-user.yaml

for i in $(seq 1 20); do
  phase=$(kubectl get mdbu search-sync-source -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || true)
  echo "  search-sync-source user phase: ${phase:-pending} ($i/20)"
  [ "$phase" = "Updated" ] && break
  sleep 10
done

kubectl apply -f manifests/06-search.yaml

for i in $(seq 1 30); do
  phase=$(kubectl get mdbs my-replica-set-search -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || true)
  echo "  my-replica-set-search phase: ${phase:-pending} ($i/30)"
  [ "$phase" = "Running" ] && break
  sleep 15
done

kubectl get mdbs -n "$NAMESPACE"
kubectl get pods -n "$NAMESPACE" -l app=my-replica-set-search-search
