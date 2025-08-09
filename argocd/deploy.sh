minikube start -p demo \
  --driver=docker \
  --kubernetes-version=stable \
  --nodes=2 \
  --cpus=2 \
  --memory=4g \
  --disk-size=3g \
&& minikube -p demo addons enable metrics-server \
&& minikube -p demo addons enable dashboard

minikube -p demo addons list | grep -E 'metrics-server|dashboard|ingress'
kubectl get nodes -o wide

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl config set-context --current --namespace=argocd

watch kubectl get all

minikube -p demo service argocd-server -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:443

argocd admin initial-password -n argocd
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 --decode; echo

argocd login localhost:8080 --insecure

argocd account update-password

minikube -p demo dashboard --url
kubectl delete -n argocd secret argocd-initial-admin-secret

kubectl port-forward svc/hello -n demo 8181:80
kubectl port-forward svc/demo-app -n demo 8181:80

minikube delete -p demo