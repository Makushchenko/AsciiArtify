## Auto-Sync ArgoCD with GitHub

### MVP ArgoCD Demo
![🎥 Watch ArgoCD Demo](../argocd/MVP-ArgoCD-Demo.gif)

To enable automatic deployment from a GitHub repository in ArgoCD:

### 1. **Connect the GitHub Repo**
   In the ArgoCD UI, go to **Settings → Repositories** and add your GitHub repo (HTTPS or SSH).

### 2. **Create or Edit an Application**
   Set the `repoURL` to your GitHub repository and `path` to the Kubernetes manifests or Helm chart.

### 3. **Enable Auto-Sync**
   In the Application's **SYNC POLICY**, enable:

   * **Automatic**: ArgoCD will apply changes whenever new commits appear in the repo.
   * **Prune Resources** *(optional)*: Removes resources deleted in Git.
   * **Self-Heal** *(optional)*: Restores drifted resources to match Git.

Example `Application` manifest with auto-sync:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

### 4. **Triggering Sync**
   Any push to the GitHub repo branch specified in `targetRevision` will automatically trigger a sync and deploy changes to your cluster.
