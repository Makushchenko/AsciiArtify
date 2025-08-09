kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

minikube -p demo service argocd-server -n argocd
    http://127.0.0.1:37189
    http://127.0.0.1:35375

kubectl config set-context --current --namespace=argocd

argocd admin initial-password -n argocd
L6X7t8jv2T07ni8-

argocd login 127.0.0.1:37189 --insecure

argocd account update-password

kubectl delete -n argocd secret argocd-initial-admin-secret