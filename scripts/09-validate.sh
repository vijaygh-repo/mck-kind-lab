#!/usr/bin/env bash
# 09-validate.sh
# Prints a consolidated health check of every resource created by this lab.
set -euo pipefail

NAMESPACE="mongodb"

section() { echo -e "\n\033[1;36m== $* ==\033[0m"; }

section "Nodes"
kubectl get nodes -o wide

section "Operator"
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=mongodb-kubernetes-operator

section "Ops Manager"
kubectl get om -n "$NAMESPACE" -o wide

section "Backup stores (oplog / blockstore)"
kubectl get mdb oplog-rs blockstore-rs -n "$NAMESPACE" -o wide

section "Workload replica set"
kubectl get mdb my-replica-set -n "$NAMESPACE" -o wide

section "Search user"
kubectl get mdbu -n "$NAMESPACE"

section "MongoDBSearch (mongot)"
kubectl get mdbs -n "$NAMESPACE" -o wide

section "All pods in namespace"
kubectl get pods -n "$NAMESPACE"

section "Next manual check"
echo "Open http://localhost:8080 -> Project -> Deployments -> my-replica-set -> Backup tab"
echo "Confirm Oplog Store / Blockstore status is green and a first snapshot completes."
