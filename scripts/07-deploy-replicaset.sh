#!/usr/bin/env bash
# 07-deploy-replicaset.sh
# Deploys the workload MongoDB replica set with backup enabled.
set -euo pipefail
cd "$(dirname "$0")/.."

NAMESPACE="mongodb"

log() { echo -e "\033[1;32m[replica-set]\033[0m $*"; }

kubectl apply -f manifests/04-replica-set.yaml

for i in $(seq 1 40); do
  phase=$(kubectl get mdb my-replica-set -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || true)
  echo "  my-replica-set phase: ${phase:-pending} ($i/40)"
  [ "$phase" = "Running" ] && break
  sleep 15
done

kubectl get mdb my-replica-set -n "$NAMESPACE"
log "Enable/verify the snapshot schedule for this deployment's Blockstore backup in the Ops Manager UI: Project -> Deployment -> Backup tab."
