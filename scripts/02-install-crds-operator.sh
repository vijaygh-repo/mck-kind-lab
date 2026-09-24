#!/usr/bin/env bash
# 02-install-crds-operator.sh
# Applies MCK 1.12.0 CRDs and installs the operator via Helm, scoped to the "mongodb" namespace.
set -euo pipefail

MCK_VERSION="1.12.0"
NAMESPACE="mongodb"

log() { echo -e "\033[1;32m[operator]\033[0m $*"; }

log "Creating namespace '$NAMESPACE' (if missing)"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

log "Applying MCK ${MCK_VERSION} CRDs"
kubectl apply -f "https://raw.githubusercontent.com/mongodb/mongodb-kubernetes/refs/tags/${MCK_VERSION}/public/crds.yaml"

log "Waiting for CRDs to be established"
for crd in mongodb.mongodb.com mongodbopsmanagers.mongodb.com mongodbusers.mongodb.com mongodbsearch.mongodb.com; do
  kubectl wait --for=condition=Established "crd/${crd}" --timeout=60s
done

log "Adding mongodb Helm repo"
helm repo add mongodb https://mongodb.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

log "Installing/upgrading mongodb-kubernetes-operator ${MCK_VERSION}"
helm upgrade --install mongodb-kubernetes-operator mongodb/mongodb-kubernetes-operator \
  --namespace "$NAMESPACE" \
  --version "$MCK_VERSION" \
  --set operator.watchNamespace="$NAMESPACE" \
  --wait --timeout 5m

log "Operator pod status:"
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=mongodb-kubernetes-operator
