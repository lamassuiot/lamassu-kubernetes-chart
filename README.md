# Lamassu on Kubernetes Helm Chart

## Overview

This is the Official Helm chart for installing and configuring Lamassu IoT on Kubernetes.

## Prerequisites - Kubernetes setup

* **Helm 3.2+**
* **Kubernetes 1.24** (This is the earliest tested version, it may work in previous and later versions)

It is also mandatory to have the following plugins enabled on the kubernetes cluster

* **MicroK8S**
  - **StorageClass**: This distribution already has a default Storage Class provisioner `microk8s.io/hostpath` named `microk8s-hostpath`
  - **CoreDNS**: This service is not provisioned by default. Run the following command to enable it
    ```bash
    microk8s enable dns
    ```
  - **Load Balancer**: To enable the load balancer plugin Run `microk8s enable metallb` specifying the CIDR range used by MetalLB i.e. 
    ```bash
    microk8s enable metallb:192.168.1.240/24
    ```
  - **Ingress Controller**:  This distribution has an easy way of installing this plugin by running:
    ```bash
    microk8s enable ingress
    ``` 
  
    Once the ingress controller is installed, apply this patch to allow mutual TLS connections to go through the nginx controller 
    ```bash
    microk8s kubectl -n ingress patch ds nginx-ingress-microk8s-controller --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-ssl-passthrough"}]'
    ```
  - **CertManager**: To enable the plugin run:
    ```bash 
    microk8s enable cert-manager
    ``````


## Installing External Components

Specify the namespace to install the components (i.e. lamassu-dev):

```bash
export NS=lamassu-dev
kubectl create ns $NS
```

### Database

#### Postgres (Standalone)

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install postgres bitnami/postgresql -n $NS -f https://raw.githubusercontent.com/lamassuiot/lamassu-helm/main/oss-helm-values/postgres.yaml
```

## Installing Lamassu



### Core deployment

Create a file named `lamassu-values.yaml` with the following content. Pay attention to the `domain` variable and use your preferred domain. 

```yaml
domain: dev.lamassu.io 
storageClassName: microk8s-hostpath
debugMode: true
postgres:
  hostname: "postgresql"
  port: 5432
  username: "admin"
  password: "admin"
ingress:
  annotations: |
    kubernetes.io/ingress.class: "public"
```

Finally instal Lamassu:

```bash
helm repo add lamassuiot http://www.lamassu.io/lamassu-helm
helm repo update
helm install lamassu lamassuiot/lamassu -n $NS -f lamassu-values.yaml
```

Once all is installed, you should be able to access the UI using a browser in your domain endpoint i.e.:

```
https://dev.lamassu.io
```