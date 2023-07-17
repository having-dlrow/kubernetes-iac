#!/bin/bash

kubernetes_version=$(echo "$VERSION" | cut -d'-' -f1)
network=$(echo "$MASTER" | cut -d'.' -f1-3)
username=$(whoami)
bin_path="/usr/local/bin"

# Initialize Kubernetes
echo " >>> Initialize Kubernetes Cluster"

sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/etcd/
yes | sudo kubeadm reset

sudo kubeadm init \
 --token-ttl 0 \
 --pod-network-cidr=$K8S_POD_NETWORK_CIDR \
 --apiserver-advertise-address=$MASTER \
 --kubernetes-version=$kubernetes_version

echo " >>> CONFIGURE KUBECTL"

export KUBECONFIG=/etc/kubernetes/admin.conf
sudo mkdir -p $HOME/.kube
sudo cp -i $KUBECONFIG $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# vagrant user
mkdir -p /home/vagrant/.kube
sudo cp -i $KUBECONFIG /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
ls -al /home/vagrant/.kube

# raw_address for gitcontent
raw_git=$GIT

# config for kubernetes's network 
echo "[TASK 3] Deploy Calico network"

# config for kubernetes's network 
wget https://$raw_git/calico_v3.25.0/calico.yaml
envsubst < calico.yaml | kubectl apply -f -

# create secret for metallb 
kubectl create namespace metallb-system
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

# create configmap for metallb (192.168.30.20 - 192.168.30.120)
echo "apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: metallb-ip-range
      protocol: layer2
      addresses:
      - $network.20-$network.120"
#######  ---------------- info ---------------- ####
echo "apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: metallb-ip-range
      protocol: layer2
      addresses:
      - $network.20-$network.120" | kubectl apply -f -

# config metallb for LoadBalancer service
kubectl apply -f https://$raw_git/metallb_v0.12.1/controller.yaml

kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl apply -f - -n kube-system

# install helm
curl -0L https://get.helm.sh/helm-v3.11.0-linux-amd64.tar.gz > helm-v3.11.0-linux-amd64.tar.gz
tar xvfz helm-v3.11.0-linux-amd64.tar.gz
mv linux-amd64/helm $bin_path/.
rm -f helm-v3.11.0-linux-amd64.tar.gz
rm -rf linux-amd64/

# install bash-completion for kubectl 
apt install bash-completion -y

# kubectl completion on bash-completion dir
kubectl completion bash > /etc/bash_completion.d/kubectl

# alias kubectl to k
echo 'alias k=sudo kubectl' >> ~/.bashrc
echo "alias ka='sudo kubectl apply -f'" >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

# Generate Cluster join command
echo "[TASK 3] Generate and save cluster join command to /joincluster.sh"

kubeadm token create --print-join-command | sudo tee $HOME/joincluster.sh
sudo chmod +x $HOME/joincluster.sh