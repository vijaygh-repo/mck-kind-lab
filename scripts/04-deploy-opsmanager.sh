#!/usr/bin/env bash
# 04-deploy-opsmanager.sh
# Deploys the MongoDBOpsManager CR and waits until Ops Manager + AppDB report Running.
set -euo pipefail
cd "$(dirname "$0")/.."

NAMESPACE="mongodb"

log() { echo -e "\033[1;32m[ops-manager]\033[0m $*"; }

kubectl apply -f manifests/01-ops-manager.yaml

log "Waiting for AppDB to become Running (this pulls MongoDB Enterprise images, can take several minutes)"
for i in $(seq 1 60); do
  phase=$(kubectl get om ops-manager -n "$NAMESPACE" -o jsonpath='{.status.applicationDatabase.phase}' 2>/dev/null || true)
  echo "  AppDB phase: ${phase:-pending} ($i/60)"
  [ "$phase" = "Running" ] && break
  sleep 15
done

log "Waiting for Ops Manager to become Running"
for i in $(seq 1 60); do
  phase=$(kubectl get om ops-manager -n "$NAMESPACE" -o jsonpath='{.status.opsManager.phase}' 2>/dev/null || true)
  echo "  Ops Manager phase: ${phase:-pending} ($i/60)"
  [ "$phase" = "Running" ] && break
  sleep 15
done

kubectl get om ops-manager -n "$NAMESPACE"
kubectl get pods -n "$NAMESPACE"

log "Ops Manager UI will be reachable at http://localhost:8080 on the EC2 host (mapped via kind extraPortMappings)."
log "If accessing from your laptop, SSH-tunnel: ssh -L 8080:localhost:8080 <user>@<ec2-public-ip>"
