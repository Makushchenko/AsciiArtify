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

echo "[3/7] Installing latest stable kubectl..."
LATEST_K8S=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO https://dl.k8s.io/release/${LATEST_K8S}/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "[4/7] Installing latest stable Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install -o root -g root -m 0755 minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

echo "[5/7] Configuring host network for Kubernetes..."
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee /etc/sysctl.d/99-k8s.conf
sudo sysctl --system

echo "[6/7] Starting Minikube with latest Kubernetes..."
minikube start \
  --driver=docker \
  --kubernetes-version=stable \
  --cpus=2 --memory=4096 --disk-size=20g \
  --addons=metrics-server,ingress

echo "[7/7] Creating namespace..."
kubectl create namespace demo || true

echo "[Deploy] Applying secure Hello World deployment, Service, HPA, and NetworkPolicy..."
kubectl apply -f ../hello-deploy.yaml

echo "[Done] Cluster is ready!"
echo "Run: minikube -n demo service hello --url"
echo "OR"
echo "Run: kubectl -n demo port-forward svc/hello 8080:80"