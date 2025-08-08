# Minikube Hello World Demo

This project demonstrates deploying a **secure NGINX "Hello World" application** to a local [Minikube](https://minikube.sigs.k8s.io/) Kubernetes cluster, following production best practices.

## Resources Created

### Namespace
- **`demo`** — Isolates all resources from other workloads.

### Deployment
- **Name:** `hello`
- **Image:** `nginxdemos/hello:plain-text`
- **Security:**
  - Non-root user (`runAsNonRoot: true`)
  - Read-only root filesystem
  - Dropped Linux capabilities
  - Writable scratch directories mounted via `emptyDir`
- **Probes:**
  - Liveness & Readiness HTTP probes on `/`
- **Replicas:** 2
- **Resource Requests/Limits:** CPU: 100m/300m, Memory: 64Mi/128Mi

### Service
- **Type:** `ClusterIP`
- **Name:** `hello`
- **Port:** 80
- Used for in-cluster communication; accessed locally via `kubectl port-forward`.

### HorizontalPodAutoscaler (HPA)
- **Name:** `hello-hpa`
- Scales the `hello` Deployment between 2–5 replicas when average CPU utilization >70%.

### NetworkPolicy
- **Name:** `hello-deny-all-except-same-ns`
- Denies all ingress except from pods in the same namespace.
- Egress allowed to all namespaces (can be restricted further).

## Accessing the Application

Since the Service is `ClusterIP`, use `kubectl port-forward` to access it locally:

```bash
kubectl -n demo port-forward svc/hello 8080:80
```

Then open:  
[http://localhost:8080](http://localhost:8080)

## Cleanup

To remove all demo resources:

```bash
kubectl delete namespace demo
minikube delete
```

## References
- [Minikube Docs](https://minikube.sigs.k8s.io/docs/)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
## Runtime Drivers

This demo can run Minikube using either:

- **Docker driver** (default in this guide) — works with Docker Engine installed locally.
- **Podman driver** — works with Podman (v4.9.0 or newer) installed locally, supports rootless mode.

Choose the driver by specifying `--driver=docker` or `--driver=podman` when starting Minikube.