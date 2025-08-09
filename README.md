## Kubernetes Local Tools & ArgoCD Deployment

This week focuses on understanding, selecting, and comparing **Kubernetes local development tools** alongside implementing **ArgoCD** for GitOps-based application deployment.

### Concept

The goal is to explore local Kubernetes solutions (e.g., Minikube, Kind, K3d) for testing and development, then extend these learnings to continuous deployment using ArgoCD.

### Proof of Concept (PoC)

We validate different local Kubernetes environments by deploying a simple application and evaluating factors such as:

* Ease of setup
* Resource usage
* Feature set (e.g., ingress, metrics-server, dashboard)
* Compatibility with ArgoCD

### Minimum Viable Product (MVP)

* A running local Kubernetes cluster using the selected tool
* ArgoCD installed and configured
* An application deployed from a Git repository via ArgoCD Auto-Sync
* Documentation outlining the setup and comparison findings

By the end of this week, we will have both a functional GitOps pipeline and a clear understanding of which local Kubernetes tool best suits our development workflow.
