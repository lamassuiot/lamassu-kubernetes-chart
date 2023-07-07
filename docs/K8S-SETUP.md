* **StorageClass Provisioner** There is no particular plugin as it depends on the Kubernetes distribution used.
  * `MicroK8s`: This distribution already has a default Storage Class provisioner `microk8s.io/hostpath` named `microk8s-hostpath`
  * `k3s`: The default installation of k3s already has a Storage Class provisioner `rancher.io/local-path` named `local-path`
  * `Minikube`: The default installation of k3s already has a Storage Class provisioner `k8s.io/minikube-hostpath` named `standard`
  * `EKS`: TODO
* **CoreDNS** Most distributions already include this component on the default installation of the cluster.
  * `MicroK8s`: This service is not provisioned by default. Run `microk8s enable dns`
  * `k3s`: The default installation includes this service
  * `Minikube`: The default installation includes this service
  * `EKS`: TODO
* **Ingress Controller** The recommended ingress controller is provided by Nginx. Follow the official documentation to install this plugin: [https://kubernetes.github.io/ingress-nginx/](https://kubernetes.github.io/ingress-nginx/).
  * `MicroK8s`: This distribution has an easy way of installing this plugin. Run `microk8s enable ingress`. Once the ingress controller is installed, apply this patch to allow mutual TLS connections to go through the nginx controller `microk8s kubectl -n ingress patch ds nginx-ingress-microk8s-controller --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-ssl-passthrough"}]'`
  * `k3s`: Follow the official docs
  * `Minikube`: Run `minikube addons enable ingress`
  * `EKS`: TODO
* **Load Balancer Provider**
  * `MicroK8s`: This distribution has an easy way of installing this plugin. Run `microk8s enable metallb` and follow the instructions. You will have to specify the CIDR range used by MetalLB i.e. `microk8s enable metallb:192.168.1.240/24`
  * `k3s`: The default installation includes this service
  * `Minikube`:  Run `minikube addons enable metallb`
  * `EKS`: TODO
* **CertManager** Follow the official docs [https://cert-manager.io/](https://cert-manager.io/)
  * `MicroK8s`: This distribution has an easy way of installing this plugin. Run `microk8s enable cert-manager`
  * `k3s`: Follow the official docs
  * `Minikube`: TODO
  * `EKS`: TODO
* **Reloader** Follow the official docs [https://github.com/stakater/Reloader](https://github.com/stakater/Reloader)
