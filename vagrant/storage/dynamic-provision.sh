#!/bin/bash

if [[ -z "${NFS_SERVER}" ]]; then
    NFS_SERVER=$(hostname).example.com
fi

# nfs client 
sudo apt-get -y install nfs-common cifs-utils
showmount -e $NFS_SERVER

echo " >>> NFS DYNAMIC PORIVISIONING"
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/nfs-subdir-external-provisioner/master/deploy/rbac.yaml

echo " >>> NFS PROVISIONER DEPLOYMENT"
echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  namespace: default
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: registry.k8s.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: k8s-sigs.io/nfs-subdir-external-provisioner
            - name: NFS_SERVER
              value: $NFS_SERVER
            - name: NFS_PATH
              value: /nfsdir/k8s
      volumes:
        - name: nfs-client-root
          nfs:
            server: $NFS_SERVER
            path: /nfsdir/k8s " | kubectl apply -f -

echo " >>> NFS DYNAMIC PROVISIONER STORAGE CLASS(nfs-client)"
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/nfs-subdir-external-provisioner/master/deploy/class.yaml

echo " >>> PVC 생성"
echo "apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mypvc-dynamic
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Mi " | kubectl apply -f -

# db
echo " >>> DYNAMIC PROVISIONING VOLUME APP"
echo "apiVersion: v1
kind: Service
metadata: 
  name: mysqldb-2
  labels:
    name: mysql-service-2
spec:
  ports:
    - port: 3306
      targetPort: 3306
  selector:
    app: mysqldb-2
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-deploy-2
  labels:
   app: mysqldb-2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysqldb-2
  template:
    metadata:
      labels:
        app: mysqldb-2
    spec:
      containers:
      - name: mysqldb-2
        image: mysql:5.7
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3306
        volumeMounts:
        - mountPath: "/var/lib/mysql"
          name: nfs-data
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: Password123
        - name: MYSQL_DATABASE
          value: crud-db
      volumes:
      - name: nfs-data
        persistentVolumeClaim:
          claimName: mypvc-dynamic " | kubectl apply -f -


# [동작 순서]
# 1. PersistentVolumeClaim <----- StorageClass를 사용하여,      ** (동적 프로비저닝) 트리거
# 2. Dynamic Provisioning  <----- PersistentVolumeClaim에 의해  ** (동적 프로비저닝) 트리거
# 3. volume provisioner 호출되면, 
#                         value(Parameter type) 와 CreateVolume 을 volume provisioner로 전달
# 4. volume provisioner는 새 볼륨을 생성한 후, 
#                         생성한 볼륨을 나타내는 PersistentVolume 개체를 자동으로 생성
# 5. Kubernetes는 새로운 PV 개체를 PVC에 바인딩, Pod는 PVC을 volume으로 사용.

