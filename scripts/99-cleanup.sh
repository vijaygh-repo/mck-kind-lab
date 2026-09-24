#!/usr/bin/env bash
# 99-cleanup.sh
# Tears down the entire lab: deletes the kind cluster (destructive, irreversible for local state).
set -euo pipefail

CLUSTER_NAME="mck-lab"

read -rp "This will delete the kind cluster '${CLUSTER_NAME}' and all data in it. Continue? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

kind delete cluster --name "$CLUSTER_NAME"
echo "Cluster deleted."
