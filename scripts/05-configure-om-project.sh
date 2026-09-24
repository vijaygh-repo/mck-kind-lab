#!/usr/bin/env bash
# 05-configure-om-project.sh
# Called automatically by run-all.sh - you do not run this by hand.
# It pauses the automated run once (Ops Manager has no headless way to create
# its first Organization/Project/API Key) and resumes as soon as you paste in
# the 4 values it asks for.
set -euo pipefail

NAMESPACE="mongodb"
CREDENTIALS_SECRET="my-credentials"
PROJECT_CONFIGMAP="my-project"

log() { echo -e "\033[1;32m[om-project]\033[0m $*"; }

OM_USER=$(kubectl get secret ops-manager-admin -n "$NAMESPACE" -o jsonpath='{.data.Username}' | base64 -d)
OM_PASS=$(kubectl get secret ops-manager-admin -n "$NAMESPACE" -o jsonpath='{.data.Password}' | base64 -d)

cat <<EOF

###################################################################
#  run-all.sh IS PAUSED HERE - IT WILL WAIT AS LONG AS YOU NEED   #
###################################################################

This is the only manual step in the whole lab. Ops Manager itself
has no headless way to create its first Organization/Project/API
Key, so do the following once in your browser, then come back to
this terminal:

  1. Open http://localhost:8080
     (from your laptop instead: ssh -L 8080:localhost:8080 <user>@<ec2-ip>)
  2. Log in with:
       Username: ${OM_USER}
       Password: ${OM_PASS}
  3. Create an Organization, e.g. "mck-lab-org".
  4. Inside it, create a Project, e.g. "mck-lab-project".
  5. Project -> Access Manager -> API Keys -> Create API Key.
       - Permissions: Project Owner
       - Whitelist: 0.0.0.0/0 (lab only - never do this in production)
       - Copy the Public Key and Private Key when shown (private key shown once).
  6. Note the Organization ID (Organizations list -> "..." -> View Organization,
     or from the browser URL).

Then answer the 4 prompts below and this script (and run-all.sh) will continue
automatically - nothing else to run by hand.
###################################################################

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
