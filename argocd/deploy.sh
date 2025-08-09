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

argocd admin initial-password -n argocd

argocd login 127.0.0.1:46583 --insecure

argocd account update-password

minikube -p demo dashboard --url
kubectl delete -n argocd secret argocd-initial-admin-secret

minikube delete -p demo