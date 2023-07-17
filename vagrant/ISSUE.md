# issue
```
 couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused
```
# solve
```
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown $(id -u):$(id -g) /home/vagrant/.kube/config
ls -al /home/vagrant/.kube
```


# issue
```
FATA[0000] validate service connection: CRI v1 runtime API is not implemented for endpoint "unix:///run/containerd/containerd.sock": rpc error: code = Unimplemented desc = unknown service runtime.v1.RuntimeService
```
# solve
```
rm -rf /etc/containerd/config.toml
systemctl restart containerd
```


# issue
```
crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a | grep kube | grep -v pause
E0626 16:41:41.546898   17709 remote_runtime.go:390] "ListContainers with filter from runtime service failed" err="rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing dial unix /var/run/containerd/containerd.sock: connect: permission denied\"" filter="&ContainerFilter{Id:,State:nil,PodSandboxId:,LabelSelector:map[string]string{},}"
FATA[0000] listing containers: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing dial unix /var/run/containerd/containerd.sock: connect: permission denied"
```

# solve
```
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
```

# issue
```
Timed out while waiting for the machine to boot. This means that
Vagrant was unable to communicate with the guest machine within
the configured ("config.vm.boot_timeout" value) time period.
```
# solve


# issue
```
couldn't get current server API group list: Get "https://192.168.30.100:6443/api?timeout=32s": net/http: TLS handshake timeout
```
# solve
```
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```


# issue
```
Output: mount.nfs: mounting 192.168.30.101:/nfsdir/default-mypvc-dynamic-pvc-fc1089ba-f61c-476d-a4f4-edd2a842b4c9 failed, reason given by server: No such file or directory

refused mount request from 192.168.30.101 for /nfsdir (/nfsdir): unmatched host
```
# solve
master 노드에 apt install nfs-common



# issue
```
Internal error occurred: failed calling webhook "validate.nginx.ingress.kubernetes.io": failed to call webhook
```
# solve
kubectl delete validatingwebhookconfiguration ingress-nginx-admission



# issue
```
NFS: state manager: check lease failed on NFSv4 server 192.168.30.101 with error 13
```
# solve
- example.com으로 도멘인 통일.
$NFS_DIR  *.example.com(rw,no_root_squash,sync,no_subtree_check)
