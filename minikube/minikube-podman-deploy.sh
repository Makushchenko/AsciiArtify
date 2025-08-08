#!/usr/bin/env bash
set -euo pipefail

echo "[1/6] Updating system and installing prerequisites..."
sudo apt update && sudo apt install -y curl ca-certificates gnupg apt-transport-https lsb-release uidmap

echo "[2/6] Installing Podman..."
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

echo "[4/6] Installing latest stable kubectl..."
LATEST_K8S=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO https://dl.k8s.io/release/${LATEST_K8S}/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "[5/6] Installing latest stable Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install -o root -g root -m 0755 minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

echo "[6/6] Starting Minikube with Podman driver..."
minikube config set rootless true
minikube start \
  --driver=podman \
  --kubernetes-version=stable \
  --cpus=2 --memory=4096 --disk-size=20g \
  --addons=metrics-server,ingress


echo "[Deploy] Creating namespace..."
kubectl create namespace demo || true

echo "[Deploy] Applying Hello World Deployment..."
kubectl apply -f ../hello-deploy.yaml

echo "[Done] Cluster is ready!"
echo "Run: minikube -n demo service hello --url"
echo "OR"
echo "Run: kubectl -n demo port-forward svc/hello 8080:80"