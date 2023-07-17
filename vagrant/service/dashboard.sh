#!/bin/bash

echo " >>> INGRESS CONTROLLER"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud/deploy.yaml

sleep 1

echo " >>> cert"

sudo mkdir /certs
cd /certs
sudo openssl genrsa -des3 -passout pass:x -out dashboard.pass.key 2048
sudo openssl rsa -passin pass:x -in dashboard.pass.key -out dashboard.key
sudo openssl req -new -key dashboard.key -out dashboard.csr \
    -subj "/C=AU/ST=State/L=City/O=Organization/OU=Department/CN=CommonName"

echo " >>> ssl cert"
sudo openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt

echo " >>> k8s secret"
sudo  chmod 777 /certs/*
kubectl create secret generic kubernetes-dashboard-certs --from-file=/certs -n kube-system

echo " >>> Dashboard ServiceAccount"
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

cat <<EOF | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

echo " >>> Dashboard"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.0/aio/deploy/recommended.yaml

# ingress
echo "apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: kubernetes-dashboard
  name: kubernetes-dashboard-ingress
  annotations:
    kubernetes.io/ingress.class: 'nginx'
    nginx.ingress.kubernetes.io/secure-backends: 'true'
    nginx.ingress.kubernetes.io/backend-protocol: 'HTTPS'
    nginx.ingress.kubernetes.io/ssl-passthrough: 'true'
    nginx.org/ssl-backend: 'kubernetes-dashboard'
    kubernetes.io/ingress.allow-http: 'false'
spec:
  tls:
  - hosts:
    - dashboard.k8s.stage
    secretName: kubernetes-dashboard-cert
  rules:
  - host: dashboard.k8s.stage
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kubernetes-dashboard
            port:
              number: 443" | kubectl apply -f -

echo "https://dashboard.k8s.stage"         

# 토큰
echo " >>> Token"
kubectl -n kubernetes-dashboard create token admin-user --duration=4880h




# 포트 포워드
# sudo nohup kubectl proxy --address='0.0.0.0' --port=$1 --accept-hosts='^*$' > /dev/null 2>&1 &
# echo http://localhost:$1/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/     

# secure 안하고 그냥 연결하는 방법
# kubectl edit deploy kubernetes-dashboard -n kubernetes-dashboard
#   // args를 찾아 다음과 같이 추가해준다. args는 39번째 줄에 있다.
# 
    #  - args:
    #    - --enable-skip-login
    #    - --disable-settings-authorizer
    #    - --insecure-bind-address=0.0.0.0       
    #    - --auto-generate-certificates
    #    - --namespace=kubernetes-dashboard
