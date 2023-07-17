#!/bin/bash

apt-get install -y sshpass

password=kubeadmin
# Run the scp command with password input
mkdir -p /home/vagrant/.kube/
sshpass -p "$password" scp -o StrictHostKeyChecking=no root@k8s-master:/etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

sshpass -p "$password" scp -o StrictHostKeyChecking=no root@k8s-master:~/joincluster.sh ~/joincluster.sh
sudo chown $(id -u):$(id -g) ~/joincluster.sh

sudo bash ~/joincluster.sh