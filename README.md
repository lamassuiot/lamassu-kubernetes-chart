# Lamassu on Kubernetes Helm Chart

## Overview

This is the Official Helm chart for installing and configuring Lamassu IoT on Kubernetes.


### Prerequisites
  * **Helm 3.2+**
  * **Kubernetes 1.24** (This is the earliest tested version, it may work in previous versions)
  > **Pro tip**
  > This helm chart can be deployed together with Rancher 

### Usage

Detailed installation instructions for Consul on Kubernetes are found [here](https://www.consul.io/docs/k8s/installation/overview). 

1. Add the HashiCorp Helm Repository:
    ``` bash
    $ helm repo add hashicorp https://helm.releases.hashicorp.com
    ```
    
2. Ensure you have access to the Consul Helm chart and you see the latest chart version listed. 
   If you have previously added the HashiCorp Helm repository, run `helm repo update`.

   ```bash
   $ helm search repo hashicorp/consul
   ```

3. Now you're ready to install Consul! To install Consul with the default configuration using Helm 3.2 run the following command below. 
   This will create a `consul` Kubernetes namespace if not already present, and install Consul on the dedicated namespace.

   ```bash
   $ helm install consul hashicorp/consul --set global.name=consul --create-namespace -n consul
   ```

Please see the many options supported in the `values.yaml`
file. These are also fully documented directly on the
[Consul website](https://www.consul.io/docs/platform/k8s/helm.html).

### Variables
