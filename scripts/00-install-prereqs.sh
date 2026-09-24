#!/usr/bin/env bash
# 00-install-prereqs.sh
# Installs Docker, kubectl, kind and helm on an EC2 instance (Amazon Linux 2023 or Ubuntu 22.04/24.04).
set -euo pipefail

KIND_VERSION="v0.26.0"
KUBECTL_VERSION="v1.31.0"

log() { echo -e "\033[1;32m[prereqs]\033[0m $*"; }

if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  echo "Cannot detect OS (missing /etc/os-release)"; exit 1
fi

log "Detected OS: $ID $VERSION_ID"

install_docker_amzn() {
  sudo dnf install -y docker || sudo yum install -y docker
  sudo systemctl enable docker
  sudo systemctl start docker
}

install_docker_ubuntu() {
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo systemctl enable docker
  sudo systemctl start docker
}

case "$ID" in
  amzn) install_docker_amzn ;;
  ubuntu) install_docker_ubuntu ;;
  *) echo "Unsupported OS: $ID. Install Docker manually and re-run."; exit 1 ;;
esac

log "Docker service status:"
sudo systemctl status docker --no-pager | head -5

if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  log "Added $USER to docker group. Log out/in (or run 'newgrp docker') before continuing."
fi

log "Installing kubectl ${KUBECTL_VERSION}"
curl -fsSLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

log "Installing kind ${KIND_VERSION}"
curl -fsSLo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
chmod +x kind
sudo mv kind /usr/local/bin/kind

log "Installing helm"
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

log "Versions installed:"
docker --version
kubectl version --client
kind version
helm version

log "Done. If you were just added to the docker group, start a new shell before running 01-create-cluster.sh"
