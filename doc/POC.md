## Getting Started with ArgoCD on Minikube

This guide provides a quick start for deploying and accessing [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) on a preinstalled Minikube cluster.

---

![🎥 Watch ArgoCD Demo](../argocd/ArgoCD-Demo.gif)

---

### 1. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Access the ArgoCD Server

Expose the ArgoCD server service via Minikube:

```bash
minikube -p demo service argocd-server -n argocd
```

This command will open the ArgoCD UI in your browser.

### 3. Get Initial Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### 4. Update Admin Password

After the first login, it is strongly recommended to change the default admin password:

```bash
argocd account update-password
```

Follow the prompts to set a new secure password.

### 5. Remove Initial Secret

Once the password has been changed, remove the initial secret for security:

```bash
kubectl -n argocd delete secret argocd-initial-admin-secret
```

### 6. Login to ArgoCD CLI

```bash
argocd login <ARGOCD_SERVER_URL>
```

Use `admin` as the username and the new password you set.
