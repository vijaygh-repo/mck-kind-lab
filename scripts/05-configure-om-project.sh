#!/usr/bin/env bash
# 05-configure-om-project.sh
# One manual step is unavoidable here: MCK cannot self-service its own Ops Manager
# Organization/Project/Programmatic API Key - that first key must be created once
# through the Ops Manager UI. This script tells you exactly what to click, then
# creates the Secret + ConfigMap the MongoDB CR needs from the values you paste in.
set -euo pipefail

NAMESPACE="mongodb"
CREDENTIALS_SECRET="my-credentials"
PROJECT_CONFIGMAP="my-project"

log() { echo -e "\033[1;32m[om-project]\033[0m $*"; }

cat <<'EOF'
=================================================================
MANUAL STEP - do this once in the Ops Manager UI
=================================================================
1. Open http://localhost:8080 (tunnel/port-forward it if you're not on the EC2 host).
2. Log in with the Username/Password stored in the "ops-manager-admin" secret:
     kubectl get secret ops-manager-admin -n mongodb -o jsonpath='{.data.Username}' | base64 -d; echo
     kubectl get secret ops-manager-admin -n mongodb -o jsonpath='{.data.Password}' | base64 -d; echo
3. Create an Organization, e.g. "mck-lab-org".
4. Inside it, create a Project, e.g. "mck-lab-project".
5. Project -> Access Manager -> API Keys -> Create API Key.
     - Permissions: Project Owner
     - Whitelist: 0.0.0.0/0 (lab only - do not do this in production)
     - Copy the Public Key and Private Key when shown (private key is shown once).
6. Note the Organization ID (Organizations list -> "..." -> View Organization, or from the URL).
=================================================================
EOF

read -rp "Organization ID: " ORG_ID
read -rp "Project name (exactly as created): " PROJECT_NAME
read -rp "Public Key: " PUBLIC_KEY
read -rsp "Private Key: " PRIVATE_KEY
echo

kubectl create secret generic "$CREDENTIALS_SECRET" \
  --namespace "$NAMESPACE" \
  --from-literal=user="$PUBLIC_KEY" \
  --from-literal=publicApiKey="$PRIVATE_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap "$PROJECT_CONFIGMAP" \
  --namespace "$NAMESPACE" \
  --from-literal=baseUrl="http://ops-manager-svc.mongodb.svc.cluster.local:8080" \
  --from-literal=projectName="$PROJECT_NAME" \
  --from-literal=orgId="$ORG_ID" \
  --dry-run=client -o yaml | kubectl apply -f -

log "Created Secret/${CREDENTIALS_SECRET} and ConfigMap/${PROJECT_CONFIGMAP} in namespace ${NAMESPACE}."
log "MongoDB resources can now reference credentials: ${CREDENTIALS_SECRET} and opsManager.configMapRef.name: ${PROJECT_CONFIGMAP}"
