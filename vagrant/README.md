
# info

| argument | value |
| -- | -- | 
| shared mount | /vagrant | /vagrant |
| cpu | 2 |
| memory | 2048 |


# nodes

| name | ip | host|
| -- | -- | -- |
| k8s-master  | 192.168.30.100 | k8s-master.example.com | 
| k8s-worker-1 | 192.168.30.101 | k8s-worker-1.example.com |
| k8s-worker-2 | 192.168.30.102 | k8s-worker-2.example.com |

# network
* cni : calico  [calico | flannel | weave]
```
-----------+---------------------------+--------------------------+------------
           |                           |                          |
  enp0s8|192.168.30.100         enp0s8|192.168.30.101       enp0s8|192.168.30.102
+----------+-----------+   +-----------+-----------+   +-----------+-----------+
|       [maste ]       |   |       [worker1]       |   |       [worker2]       |
|     Control Plane    |   |      Worker Node      |   |      Worker Node      |
+----------------------+   +-----------------------+   +-----------------------+
```

# node 시작 \ 재시작
```
vagrant up
```

# node 일시저장
```
vagrant halt
```

# 파드 접속 하기(ssh)
```
usename : root
password : kubeadmin
$ su root 
```
# 파드 접속하기 (vagrant ssh)
```
cd vagrant
vagrant ssh k8s-master
```

## 대시보드(with ingress) 생성
```
$/vagrant/service/dashboard.sh
```

## nfs dynamic provisioning (application: db)
```
$/vagrant/storage/nfs.sh
$/vagrant/storage/dynamic-provision.sh
```

### nfs 정적 provisioning
```
$/vagrant/storage/static-provision.sh
```

# ref.
kubernetes network : https://ikcoo.tistory.com/11

