# Kubernetes in Docker (kind) – Installation & Deployment Guide

## Overview

This guide explains how to:

1. Install **kind** (Kubernetes in Docker) on Ubuntu 24.10.
2. Create a multi-node Kubernetes cluster.
3. Deploy a **secure and minimal** “Hello World” application with HPA and NetworkPolicy.
4. Access the application locally.

---

## 1. Prerequisites

* **Ubuntu 24.10** (other Linux distros may require small changes)
* **Docker Engine** installed and running
  [Docker Installation Guide](https://docs.docker.com/engine/install/ubuntu/)
* `kubectl` installed (latest stable)
  [kubectl Install Docs](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

Verify:

```bash
docker --version
kubectl version --client
```

---

## 2. Install kind (latest version)

```bash
curl -Lo kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
sudo install -o root -g root -m 0755 kind /usr/local/bin/kind
rm kind

# Verify installation
kind --version
```

---

## 3. Create a Multi-Node Cluster

> **Note:** kind does **not** support dynamically adding or removing nodes to an existing cluster. To change the node count, you must delete and recreate the cluster with a new configuration.

Create a `kind-config.yaml` file:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

Start the cluster for Podman:

```bash
export KIND_EXPERIMENTAL_PROVIDER=podman
kind create cluster --name dev --config kind-config.yaml
```

Start the cluster for Docker:

```bash
kind create cluster --name dev --config kind-config.yaml
```

Verify:

```bash
kubectl cluster-info
kubectl get nodes -o wide
```

---

## 4. Deploy “Hello World” App

We will create and apply a manifest that includes:

* **Deployment**: Runs the hello-world application in multiple replicas with security best practices.
* **Service**: Exposes the application internally in the cluster.
* **HorizontalPodAutoscaler (HPA)**: Scales the Deployment based on CPU usage.
* **NetworkPolicy**: Restricts network access so only pods within the same namespace can communicate.

Save the manifest as `hello-deploy.yaml` and apply it:

```bash
kubectl apply -f hello-deploy.yaml
kubectl -n demo rollout status deploy/hello
```

---

## 5. Access the Application

```bash
kubectl -n demo port-forward svc/hello 8080:80
```

Then open [http://localhost:8080](http://localhost:8080) in your browser.

---

## 6. Cleanup

```bash
kubectl delete ns demo
kind delete cluster --name dev
```

---

## Notes & Best Practices

* **Security Contexts**: Containers run as non-root, with correct UID/GID, read-only filesystem, dropped Linux capabilities, and writable volumes mounted explicitly.
* **Resource Requests/Limits**: Ensures predictable scheduling.
* **Probes**: Liveness and readiness probes enable self-healing and smooth rollouts.
* **Autoscaling**: HorizontalPodAutoscaler adjusts replicas based on CPU utilization.
* **NetworkPolicy**: Restricts traffic to same-namespace pods by default.
* **Scaling**: kind does **not** support dynamic node scaling; recreate the cluster to change node count.

---

## References

* [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
* [Kubernetes Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
* [Security Contexts](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
* [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
