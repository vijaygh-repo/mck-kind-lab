#!/usr/bin/env bash
# run-all.sh
# Single entry point that runs the whole lab end to end.
# Individual scripts under scripts/ still exist for debugging/re-running one stage.
set -euo pipefail
cd "$(dirname "$0")"

SKIP_PREREQS=false
[ "${1:-}" = "--skip-prereqs" ] && SKIP_PREREQS=true

log() { echo -e "\n\033[1;35m>>> $*\033[0m"; }

if [ "$SKIP_PREREQS" = false ]; then
  log "Running scripts/00-install-prereqs.sh"
  bash scripts/00-install-prereqs.sh

  if ! docker info >/dev/null 2>&1; then
    log "Docker group membership isn't active in this shell yet. Re-executing under 'sg docker' - no manual re-login needed."
    exec sg docker -c "bash '$0' --skip-prereqs"
  fi
fi

STEPS=(
  scripts/01-create-cluster.sh
  scripts/02-install-crds-operator.sh
  scripts/03-create-secrets.sh
  scripts/04-deploy-opsmanager.sh
)
for step in "${STEPS[@]}"; do
  log "Running $step"
  bash "$step"
done

log "Running scripts/05-configure-om-project.sh (the one step that needs a few clicks in the Ops Manager UI)"
bash scripts/05-configure-om-project.sh

STEPS_AFTER=(
  scripts/06-deploy-backup-stores.sh
  scripts/07-deploy-replicaset.sh
  scripts/08-deploy-search.sh
  scripts/09-validate.sh
)
for step in "${STEPS_AFTER[@]}"; do
  log "Running $step"
  bash "$step"
done

log "Lab is up. Re-run ./scripts/09-validate.sh anytime to re-check status."
