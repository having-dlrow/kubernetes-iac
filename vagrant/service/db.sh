
#!/bin/bash

# pvc 
# echo "apiVersion: v1
# kind: PersistentVolumeClaim
# metadata:
#   name: mysql-data-disk
# spec:
#   accessModes:
#     - ReadWriteOnce
#   resources:
#     requests:
#       storage: 1Gi" | kubectl delete -f -

# db
echo "apiVersion: v1
kind: Service
metadata: 
  name: mysqldb
  labels:
    name: mysql-service
spec:
  ports:
    - port: 3306
      targetPort: 3306
  selector:
    app: mysqldb
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-deploy
  labels:
   app: mysqldb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysqldb
  template:
    metadata:
      labels:
        app: mysqldb
    spec:
      containers:
      - name: mysqldb
        image: mysql:5.7
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3306
        volumeMounts:
        - mountPath: "/var/lib/mysql"
          subPath: "mysql"
          name: mysql-data
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: Password123
        - name: MYSQL_DATABASE
          value: crud-db
      volumes:
        - name: mysql-data
          hostPath:
            path: /root/mysqld
            type: Directory" | kubectl apply -f -

# app
echo "apiVersion: v1
kind: Service
metadata: 
  name: springboot-backend
  labels:
    name: backend-service
spec:
  type: LoadBalancer
  ports:
    - port: 8020
      targetPort: 8020
  selector:
    app: backend-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
  labels:
   app: backend-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend-app
  template:
    metadata:
      labels:
        app: backend-app
    spec:
      containers:
      - name: backend-container
        image: lugar2020/crud-spring-boot
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8020
        env:
        - name: DB_HOST
          value: mysqldb
        - name: DB_NAME
          value: crud-db
        - name: DB_USERNAME
          value: root
        - name: DB_PASSWORD
          value: Password123" | kubectl apply -f -


echo "http://192.168.30.101:30006/employees/all"
echo "http://192.168.30.20{{external-ip}}:8020{{external-port}}/employees/all"
