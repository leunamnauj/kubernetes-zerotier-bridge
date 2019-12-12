# Kubernetes Zerotier bridge 

### *TL;DR*
A Zerotier gateway to access your non-public k8s services thru ZT subnet 


## Kubernetes
Since this docker image expects the subnetID as an env variable you need to use something like this
```
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: zerotier-networks
data:
  NETWORK-1-ID: << your subnetid >>
  ZTAUTHTOKEN: << your token >>
  AUTOJOIN: true
---
apiVersion: v1
kind: Pod
metadata:
  name: kubernetes-zerotier-bridge
spec:
  containers:
    - name: ubernetes-zerotier-bridge
      image: << your registry >>
      env:
      - name: NETWORK_ID
        valueFrom:
          configMapKeyRef:
            name: zerotier-networks
            key: NETWORK-1-ID 
      - name: ZTAUTHTOKEN
        valueFrom:
          configMapKeyRef:
            name: zerotier-networks
            key: ZTAUTHTOKEN 
      - name: AUTOJOIN
        valueFrom:
          configMapKeyRef:
            name: zerotier-networks
            key: AUTOJOIN 
      securityContext:
          privileged: true
          capabilities:
            add:
            - NET_ADMIN
            - SYS_ADMIN
            - CAP_NET_ADMIN
        volumeMounts:
        - name: zerotierdata
          mountPath: /var/lib/zerotier-one
        - name: dev-net-tun
          mountPath: /dev/net/tun

```
**Important:** Be aware of `securityContext` and `dev-net-tun` volume

## Zerotier level config
In order to route traffic to this POD have to add the proper rule on ZT Managed Routes section, to accomplish that you have to know the ZT address assigned to the pod and your Service and/or PODs subnet.





## Local Run
Running this locally will let you test your ZT connection and also use it without install ZT at all

### Usage

Modify docker compose file accordly.

  - modify the `NETWORK_ID` and `ZTAUTHTOKEN`
  - modify the `ROUTES` and use `<Remote Network>,<Zerotier node IP>;<another network>,<another Zerotier node IP>;...` if you would like to use Site-to-Site function between the networks. But do not forget to add the routes to your router too (because DHCP clients on LAN use default routes)!
  - You can use `config/route.list` files for route rules too. Check the example file for format. 

```
docker-compose up -d
```




## Inspired on

* https://github.com/henrist/zerotier-one-docker
* https://github.com/crocandr/docker-zerotier