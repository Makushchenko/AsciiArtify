# 0) Use a fresh Minikube profile (multi-node)
minikube start -p demo --driver=docker --kubernetes-version=stable --nodes=2 --cpus=2 --memory=4g --disk-size=3g
kubectl get nodes -o wide

# 1) Enable key addons (metrics + dashboard + ingress)
minikube -p demo addons enable metrics-server
minikube -p demo addons enable dashboard
minikube -p demo addons enable ingress
minikube -p demo addons list | grep -E 'metrics-server|dashboard|ingress'

# 2) Create a dedicated namespace
kubectl create namespace demo


# 3) Deploy a hardened "hello world" (non-root, read-only FS, probes, resources)
cat > hello-deploy.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello
  namespace: demo
  labels:
    app: hello
spec:
  replicas: 2
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      # Make the writable volumes group-writable for the container user
      securityContext:
        runAsNonRoot: true
        runAsUser: 101          # nginx user uid in many distros/images
        runAsGroup: 101
        fsGroup: 101
        fsGroupChangePolicy: "OnRootMismatch"
      containers:
        - name: hello
          image: nginxdemos/hello:plain-text
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "100m"
              memory: "64Mi"
            limits:
              cpu: "300m"
              memory: "128Mi"
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 15
            periodSeconds: 10
            failureThreshold: 3
          volumeMounts:
            - name: nginx-cache
              mountPath: /var/cache/nginx
            - name: nginx-run
              mountPath: /var/run
            - name: nginx-tmp
              mountPath: /var/tmp
      volumes:
        - name: nginx-cache
          emptyDir: {}
        - name: nginx-run
          emptyDir: {}
        - name: nginx-tmp
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: hello
  namespace: demo
  labels:
    app: hello
spec:
  type: ClusterIP
  selector:
    app: hello
  ports:
    - port: 80
      targetPort: 80
YAML

kubectl apply -f hello-deploy.yaml
kubectl -n demo rollout status deploy/hello
kubectl -n demo get deploy,po,svc -o wide
kubectl -n demo get all -o wide

# 3.1) Apply NetworkPolicy (deny all traffic except same namespace)
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: hello-deny-all-except-same-ns
  namespace: demo
spec:
  podSelector:
    matchLabels:
      app: hello
  policyTypes: ["Ingress","Egress"]
  ingress:
  - from:
    - podSelector: {}
  egress:
  - to:
    - namespaceSelector: {}
YAML

kubectl -n demo get networkpolicy


# 4) Expose via real LoadBalancer IP (minikube tunnel)
# Run this in a separate terminal and keep it running:
minikube -p demo tunnel

# 5) Get external IP and test service
kubectl -n demo get svc hello -w
# When EXTERNAL-IP is assigned, in another terminal:
HELLO_IP=$(kubectl -n demo get svc hello -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -s "http://${HELLO_IP}" | head

# 6) Kubernetes Dashboard (full UI)
minikube -p demo dashboard --url
# Open the printed URL in a browser

# 7) Metrics server demo (resource metrics)
kubectl top nodes
kubectl -n demo top pods

# 8) Autoscaling with HPA (CPU-based)
kubectl autoscale deployment -n demo hello --cpu-percent=70 --min=2 --max=5
kubectl -n demo get hpa hello -w

# 9) (Optional) Generate load to trigger HPA scaling
kubectl -n demo run loadgen --image=busybox --restart=Never -- \
  /bin/sh -c 'while true; do wget -q -O- http://hello.demo.svc.cluster.local >/dev/null; done'

# Watch metrics and HPA react
kubectl -n demo top pods
kubectl -n demo get hpa hello -w
kubectl -n demo get deploy hello -w

# 10) Ingress demo (Nginx Ingress addon)
cat > hello-ingress.yaml <<'YAML'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello
  namespace: demo
spec:
  ingressClassName: nginx
  rules:
    - host: hello.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: hello
                port:
                  number: 80
YAML

kubectl apply -f hello-ingress.yaml
kubectl -n demo get ingress hello

kubectl -n demo port-forward svc/hello 8080:80
curl http://localhost:8080

# 11) Scale up/down + rollout demo
kubectl -n demo scale deploy/hello --replicas=3
kubectl -n demo set image deploy/hello hello=nginxdemos/hello:plain-text
kubectl -n demo rollout status deploy/hello
kubectl -n demo get all -o wide

# 12) Pause/Resume, Stop/Start (lifecycle capabilities)
minikube -p demo pause
minikube -p demo unpause
minikube -p demo stop
minikube -p demo start

# 13) Cleanup
kubectl delete ns demo
minikube delete -p demo
