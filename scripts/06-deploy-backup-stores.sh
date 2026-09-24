#!/usr/bin/env bash
# 06-deploy-backup-stores.sh
# Deploys the oplog store and blockstore replica sets, waits for them, then patches
# the MongoDBOpsManager CR's spec.backup to register them.
set -euo pipefail
cd "$(dirname "$0")/.."

NAMESPACE="mongodb"

log() { echo -e "\033[1;32m[backup-stores]\033[0m $*"; }

kubectl apply -f manifests/02-backup-oplog-rs.yaml
kubectl apply -f manifests/03-backup-blockstore-rs.yaml

wait_for_running() {
  local name="$1"
  for i in $(seq 1 40); do
    phase=$(kubectl get mdb "$name" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || true)
    echo "  $name phase: ${phase:-pending} ($i/40)"
    [ "$phase" = "Running" ] && return 0
    sleep 15
  done
  echo "Timed out waiting for $name to reach Running" >&2
  return 1
}

wait_for_running oplog-rs
wait_for_running blockstore-rs

log "Patching MongoDBOpsManager/ops-manager with oplog store and blockstore references"
kubectl patch om ops-manager -n "$NAMESPACE" --type merge -p '
{
  "spec": {
    "backup": {
      "enabled": true,
      "opLogStores": [
        {"name": "oplog1", "mongodbResourceRef": {"name": "oplog-rs"}}
      ],
      "blockStores": [
        {"name": "blockstore1", "mongodbResourceRef": {"name": "blockstore-rs"}}
      ]
    }
  }
}'

log "Waiting for Ops Manager to re-reconcile with backup config"
for i in $(seq 1 40); do
  phase=$(kubectl get om ops-manager -n "$NAMESPACE" -o jsonpath='{.status.opsManager.phase}' 2>/dev/null || true)
  echo "  Ops Manager phase: ${phase:-pending} ($i/40)"
  [ "$phase" = "Running" ] && break
  sleep 15
done

kubectl get om ops-manager -n "$NAMESPACE" -o yaml | grep -A 12 "backup:"
