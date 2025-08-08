#!/usr/bin/env bash
set -euo pipefail

echo "[1/7] Updating system and installing prerequisites..."
sudo apt update && sudo apt install -y curl ca-certificates gnupg apt-transport-https lsb-release

echo "[2/7] Installing Docker Engine..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo ${UBUNTU_CODENAME:-oracular}) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"

echo "[1.1/7] Installing Podman..."
. /etc/os-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key \
  | gpg --dearmor | sudo tee /etc/apt/keyrings/libcontainers.gpg > /dev/null
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/libcontainers.gpg] \
  https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" \
  | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list > /dev/null
sudo apt update
sudo apt install -y podman

echo "[3/6] Configuring rootless Podman..."
# Enable linger so Podman services keep running after logout
loginctl enable-linger "$USER"

# Set up environment for rootless Podman
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

# Verify
podman info --log-level=error

echo "[3/7] Installing latest stable kubectl..."
LATEST_K8S=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO https://dl.k8s.io/release/${LATEST_K8S}/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "[4/7] Installing k3d (latest)..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d version

echo "[5/7] Creating k3d cluster..."
k3d cluster create dev \
  --servers 1 \
  --agents 2
kubectl cluster-info
kubectl get nodes -o wide

echo "[6/7] Creating namespace..."
kubectl create namespace demo || true

echo "[7/7] [Deploy] Applying secure Hello World deployment, Service, HPA, and NetworkPolicy..."
kubectl apply -f ../hello-deploy.yaml

echo "[Done] Cluster is ready!"
kubectl -n demo rollout status deploy/hello
echo "Run: kubectl -n demo port-forward svc/hello 8080:80"

echo "[Add nodes to cluster] Adding k3d cluster nodes..."
k3d node create agent-3 --role agent --cluster dev
kubectl get nodes -o wide
k3d node delete k3d-agent-3-0
kubectl get nodes -o wide