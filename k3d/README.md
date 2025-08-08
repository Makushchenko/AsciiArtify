# k3d (K3s in Docker) — Installation & Deployment Guide

## Overview

This guide shows how to:

1. Install **k3d** on Ubuntu/Linux
2. Create a multi‑node K3s cluster
3. Deploy a secure “Hello World” app (Deployment + Service + HPA + NetworkPolicy)
4. Access and manage the cluster

> **Note:** k3d requires **Docker**. Podman is **not supported** by k3d.

---

## 1) Prerequisites

* Docker Engine running ([https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/))
* `kubectl` installed ([https://kubernetes.io/docs/tasks/tools/](https://kubernetes.io/docs/tasks/tools/))
* Linux user in the `docker` group (log out/in after adding)

Verify:

```bash
docker --version
kubectl version --client
```

---

## 2) Install k3d

```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sudo bash
k3d version
```

---

## 3) Create a multi‑node cluster (1 server + 2 agents)

Expose HTTP via the built‑in load balancer (host `:8080` → cluster `:80`):

```bash
k3d cluster create dev \
  --servers 1 \
  --agents 2 \
  --port "8080:80@loadbalancer"
```

Set/confirm context:

```bash
kubectl config use-context k3d-dev
kubectl get nodes -o wide
```

---

## 4) Deploy “Hello World”

Create a namespace and apply your app manifest (same one you used for kind):

* **Deployment** with 2 replicas, resource requests/limits, liveness/readiness probes, non‑root user, read‑only FS
* **Service** (ClusterIP) exposing port 80
* **HPA** targeting \~70% CPU utilization
* **NetworkPolicy** limiting traffic to same‑namespace pods

```bash
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f hello-deploy.yaml
kubectl -n demo rollout status deploy/hello
```

---

## 5) Access the app

Thanks to the load balancer port mapping:

```bash
curl -s http://localhost:8080 | head
```

---

## 6) Common operations

```bash
# Inspect
kubectl get nodes,pods -A
kubectl -n demo get deploy,rs,po,svc,hpa

# Manual scale
kubectl -n demo scale deploy/hello --replicas=3

# Live logs
kubectl -n demo logs -l app=hello -f --tail=100
```

---

## 7) Dynamic node scaling (supported in k3d)

```bash
# Add a worker node
k3d node create agent-3 --role agent --cluster dev

# Remove a worker node
k3d node delete agent-3
```

---

## 8) Cleanup

```bash
kubectl delete ns demo
k3d cluster delete dev
```

---

## Notes & Best Practices

* **Security**: run as non‑root, read‑only root FS, drop capabilities, restrict write dirs with `emptyDir` as needed.
* **Resources**: set CPU/memory requests & limits for predictable scheduling.
* **Probes**: readiness for traffic gating; liveness for self‑healing.
* **Autoscaling**: K3s includes metrics‑server; HPA should work after a short warm‑up.
* **Runtime**: k3d uses **Docker**; **Podman is not supported**.