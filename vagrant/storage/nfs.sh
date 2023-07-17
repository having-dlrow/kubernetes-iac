#!/bin/bash

EXPORTS_FILE="/etc/exports"
NFS_DIR="/nfsdir/k8s"

echo " >>> NFS 서버 설치"
sudo apt-get update
sudo apt install nfs-kernel-server nfs-common -y

if [[ ! -d $NFS_DIR ]]; then
    sudo mkdir -p $NFS_DIR
    sudo chmod -R 777 $NFS_DIR
fi

if grep -q "$NFS_DIR" "$EXPORTS_FILE"; then
    echo "The NFS directory $NFS_DIR is already present in $EXPORTS_FILE."
else
    echo "$NFS_DIR  *.example.com(rw,no_root_squash,sync,no_subtree_check)" | sudo tee -a $EXPORTS_FILE
fi

echo ">>> nfs info"
sudo systemctl restart nfs-kernel-server
sudo exportfs -av
sudo exportfs -s