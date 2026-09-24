#!/usr/bin/env bash
# 01-create-cluster.sh
# Creates the kind cluster used for the whole lab.
set -euo pipefail
cd "$(dirname "$0")/.."

CLUSTER_NAME="mck-lab"

log() { echo -e "\033[1;32m[cluster]\033[0m $*"; }

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  log "Cluster '$CLUSTER_NAME' already exists, skipping create."
else
  log "Creating kind cluster '$CLUSTER_NAME'"
  kind create cluster --name "$CLUSTER_NAME" --config kind-config.yaml --wait 120s
fi

kubectl cluster-info --context "kind-${CLUSTER_NAME}"
kubectl get nodes -o wide

log "Cluster ready. KUBECONFIG context: kind-${CLUSTER_NAME}"
