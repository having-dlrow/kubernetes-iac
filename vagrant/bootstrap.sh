#!/bin/bash

echo "[TASK 2] Install docker container engine"
sudo apt-get install -y nfs-common
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# add apt repository for docker
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update

# Install docker ( docker-ce, docker-ce-cli, containerd.io )
echo "sudo apt install docker-ce=$DOCKER_VERSION -y"
sudo apt install docker-ce=$DOCKER_VERSION -y
systemctl status containerd

# disabled_plugins cri 주석 처리
echo "[TASK 3] fix - [ERROR CRI]: container runtime is not running"
rm -rf /etc/containerd/config.toml

# add account to the docker group and configure driver to use systemd
usermod -aG docker vagrant
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd


# Enable docker service
echo "[TASK 4] Enable and start docker service" 
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# kernel module
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Add sysctl settings
echo "[TASK 5] Add sysctl settings"
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Disable swap
echo "[TASK 6] Disable and turn off SWAP"
# swapoff -a to disable swapping
swapoff -a
# sed to comment the swap partition in /etc/fstab
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# ubuntu doesn't use selinux.

# Enable ssh password authentication for copy files between master and nodes
echo "[TASK 7] Enable ssh password authentication"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

# Set Root password
echo "[TASK ] Set root password"
echo -e "kubeadmin\nkubeadmin" | passwd root

# Update vagrant user's bashrc file
echo "export TERM=xterm" >> /etc/bashrc