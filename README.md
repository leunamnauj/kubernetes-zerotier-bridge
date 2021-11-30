# Kubernetes Zerotier Bridge

### *TL;DR*

A Zerotier gateway to access an kubernetes ingress though a ZT subnet. Indendet to be used for a distributet routing from a public gateway to a private kubernetes cluster. Currently only supports traefik as ingress and a single zerotier subnet.

**TODOs** Make configurable for different ingresses and subnets

## Helm chart to deploy a DaemonSet WIP

`helm repo add kubernetes-zerotier-bridge https://jakoberpf.github.io/kubernetes-zerotier-bridge/`

`helm repo update`

`helm install --name kubernetes-zerotier-bridge kubernetes-zerotier-bridge/kubernetes-zerotier-bridge`

**Note:** You are able to configure persistence setting `persistentVolume.enabled=true` and further storage parameters as needed.

## Single Deployment

Since this docker image expects the subnetIDs as an env variable you need to use something like this

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: zerotier-networks
data:
  AUTOJOIN: << true or false >>
---
apiVersion: v1
kind: Secret
metadata:
  name: zerotier-secrets
  namespace: zerotier
data:
  NETWORK_IDS: << your subnetids >>
  ZT_AUTHTOKEN: << your token >>
  ZT_HOSTNAME: << optional desired hostname>>
---
apiVersion: v1
kind: Pod
metadata:
  name: kubernetes-zerotier-bridge
spec:
  selector:
    matchLabels:
      app: zerotier-bridge
  template:
    metadata:
      labels:
        app: zerotier-bridge
    spec:
      containers:
      - name:  zerotier-bridge
        image: jakoberpf/zerotier-bridge:implement-caddy
        imagePullPolicy: Always
        envFrom:
        - configMapRef:
            name: zerotier-configmap
        env:
        - name: NETWORK_IDS
          valueFrom:
            secretKeyRef:
              name: zerotier-secrets
              key: NETWORK_IDS 
        - name: ZT_HOSTNAME
          valueFrom:
            secretKeyRef:
              name: zerotier-secrets
              key: ZT_HOSTNAME 
        - name: ZT_AUTHTOKEN
          valueFrom:
            secretKeyRef:
              name: zerotier-secrets
              key: ZT_AUTHTOKEN 
        - name: AUTOJOIN
          valueFrom:
            configMapKeyRef:
              name: zerotier-configmap
              key: AUTOJOIN 
        securityContext:
          privileged: true
          capabilities:
            add:
            - NET_ADMIN
            - SYS_ADMIN
            - CAP_NET_ADMIN
        volumeMounts:
          - name: dev-net-tun
            mountPath: /dev/net/tun
      volumes:
      - name: dev-net-tun
        hostPath:
          path: /dev/net/tun

```

**Important:** Be aware of `securityContext` and `dev-net-tun` volume

## Zerotier level config

In order to route traffic to this POD, you have to add the proper rule on ZT Managed Routes section or use an rreverse proxy to forwards the traffic.

### haproxy example

```conf

```

### Usage

Modify docker compose file accordly.

- `NETWORK_IDS` Comma separated networkIDs.
- `ZT_AUTHTOKEN` Your network token, required to perform auto join and set hostname.
- `ZT_HOSTNAME` Hostname to identify this client. If not provided will keep it blank.
- `AUTOJOIN` Automatically accept new host.

```
docker-compose up
```

## Inspired on

- <https://github.com/Intelecy/ztsc>
- <https://github.com/leunamnauj/kubernetes-zerotier-bridge>
- <https://github.com/henrist/zerotier-one-docker>
- <https://github.com/crocandr/docker-zerotier>
