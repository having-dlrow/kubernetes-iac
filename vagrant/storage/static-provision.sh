#!/bin/bash

if [[ -z "${NFS_SERVER}" ]]; then
    NFS_SERVER=$(hostname -I | awk '{print $2}')
fi

sudo apt-get -y install nfs-common cifs-utils
# nfs client 
showmount -e $NFS_SERVER

echo " >>> PV 생성"
echo "apiVersion: v1
kind: PersistentVolume
metadata:
  name: mypv-data
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  nfs:
    path: /nfsdir/k8s
    server: $NFS_SERVER    
  storageClassName: nfs-data" | kubectl apply -f -

echo " >>> PVC 생성"
echo "apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mypvc-data
spec:
  resources:
    requests:
      storage: 0.5Gi
  accessModes:
    - ReadWriteMany
  volumeName: mypv-data 
  storageClassName: nfs-data" | kubectl apply -f -

echo " >>> DEPLOYMENT 생성"
echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: nginx:latest
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        ports:
        - containerPort: 80
          protocol: TCP
        volumeMounts:
          - name: pvctest
            mountPath: /usr/share/nginx/html
      volumes:
        - name: pvctest
          persistentVolumeClaim:
            claimName: mypvc-data" | kubectl apply -f -
