# Lamassu on Kubernetes Helm Chart

## Overview

This is the Official Helm chart for installing and configuring Lamassu IoT on Kubernetes.

### Prerequisites - Kubernetes setup

* **Helm 3.2+**
* **Kubernetes 1.24** (This is the earliest tested version, it may work in previous versions)

It is also mandatory to have the following plugins enabled on the kubernetes cluster

* **SotrageClass Provisioner** There is no particular plugin as it depends on the Kubernetes distribution used.
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
  * `MicroK8s`: This distribution has an eazy way of installing this plugin. Run `microk8s enable ingress`. Once the ingress controller is installed, apply this patch to allow mutual TLS connections to go through the nginx controller `microk8s kubectl -n ingress patch ds nginx-ingress-microk8s-controller --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-ssl-passthrough"}]'`
  * `k3s`: Follow the official docs
  * `Minikube`: Run `minikube addons enable ingress`
  * `EKS`: TODO
* **Load Balancer Provider**
  * `MicroK8s`: This distribution has an eazy way of installing this plugin. Run `microk8s enable metallb` and follow the instructions. You will have to specify the CIDR range used by MetalLB i.e. `microk8s enable metallb:192.168.1.240/24`
  * `k3s`: The default installation includes this service
  * `Minikube`:  Run `minikube addons enable metallb`
  * `EKS`: TODO
* **CertManager** Follow the official docs [https://cert-manager.io/](https://cert-manager.io/)
  * `MicroK8s`: This distribution has an eazy way of installing this plugin. Run `microk8s enable cert-manager`
  * `k3s`: Follow the official docs
  * `Minikube`: TODO
  * `EKS`: TODO
* **Reloader** Follow the official docs [https://github.com/stakater/Reloader](https://github.com/stakater/Reloader)

### Verify

* Make sure your ingress controller has the SSL Passthrough enabled, otherwise the Lamassu chart won't work as expected. Refer to the Prerequisites > Ingress Controller section

* Depending on how the nginx ingress controller is installed, it may not pick the provisioned Ingress, and thus, no traffic will be routed through it. In those cases, run this commands and make sure your nginx ingress controller picks Lamassu's Ingress deffinitions:



### Usage

Steps to install this chart:

1. Clone the repo:

```bash
git clone https://github.com/lamassuiot/lamassu-kubernetes-chart
cd lamassu-kubernetes-chart
```

2. Choose the namespace to use:

```bash
export NS=lamassu
```

3. Install the helm chart. There are many ways to deploy Lamassu using this charts depending which subsytems are needed. Choose one of the following deployment modes

  **Core deployment**

  Make sure to use change the `domain` variable as well as the `storageClassName` (this can be obtained runing `kubectl get sc`)

  ```bash
  helm install lamassu . --create-namespace -n $NS \
  --set domain=dev.lamassu.io \
  --set storageClassName=local-path \
  --set debugMode=true
  ```

  **Core deployment using external Certificates (Used by API Gateway)**

  Make sure to point to the actual paths to the `.cert` file and the .key `file`
  ```bash
  #First, create secret using files with certificate and key to use:
  kubectl create secret tls external-downstream-cert -n $NS \
  --cert=path/to/cert/file \
  --key=path/to/key/file

  helm install lamassu . --create-namespace -n $NS \
  --set domain=dev.lamassu.io \
  --set storageClassName=local-path \
  --set debugMode=true
  --set tls.selfSigned=false
  --set tls.secretName=external-downstream-cert
  ```

  **Core deployment + Simulation tools**

  ```bash
  helm install lamassu . --create-namespace -n $NS \
  --set domain=dev.lamassu.io \
  --set storageClassName=local-path \
  --set debugMode=true \
  --set simulationTools.enabled=true
  ```

  **Core deployment + Alerts with email/STMP**

  The alerts service is automatically deployed, but it needs some information to connect with an external SMTP server, see the Variables secction for more information on how to configure this service

  ```bash
  helm install lamassu . --create-namespace -n $NS \
  --set domain=dev.lamassu.io \
  --set storageClassName=local-path \
  --set debugMode=true \
  --set services.alerts.smtp.from="lamassu-alerts@lamassu.io" \
  --set services.alerts.smtp.username="lamassu-alerts@lamassu.io"
  ```

  **Core deployment + AWS Connector**

  The AWS connector can also be deployed using the following command. Please note that it is required to provsion the AWS resources from [https://github.com/lamassuiot/lamassu-aws-connector]()

  Once all AWS services have been deployed via de CDK, then deploy your Lamassu instance. Make sure to change the `services.awsConnector.aws.accessKeyId`, `services.awsConnector.aws.secretAccessKey` and `services.awsConnector.aws.defaultRegion` to the appropriate values:

  ```bash
  helm install lamassu . --create-namespace -n $NS \
  --set domain=dev.lamassu.io \
  --set storageClassName=local-path \
  --set debugMode=true \
  --set services.awsConnector.enabled=true \
  --set services.awsConnector.name="My AWS Account" \
  --set services.awsConnector.aws.accessKeyId="**************" \
  --set services.awsConnector.aws.secretAccessKey="************" \
  --set services.awsConnector.aws.defaultRegion="eu-west-1" \
  --set services.awsConnector.aws.sqs.inboundQueueName="lamassuResponse"
  ```

### Clean uninstall

In order to remove all the provisioned resources, run this commands:

1. Choose the namespace where Lamassu has been deployed:

  ```bash
  export NS=lamassu
  ```

2. Uninstall the helm release:

  ```bash
  helm uninstall lamassu -n $NS
  ```

3. Remove all provisioned secrets:

  ```bash
  kubectl delete secrets -n $NS --all
  ```

4. Remove all persisten volume claims:

  ```bash
  kubectl delete pvc -n $NS --all
  ```

### Variables

| Name                                              | Description                                                                                                                  | Value                     |
|---------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------|---------------------------|
| `debugMode`                                       | Deploy services with additional logs                                                                                         | `false`                   |
| `domain`                                          | Domain to use in ingress controller and other services                                                                       | `"dev.lamassu.io"`        |
| `storageClassName`                                | Storage class to use while provisioning PersistenVolumes                                                                     | `""`                      |
| `tls.selfSigned`                                  | If true, a self signed certificate will be generated and used for downstream connections by the API-Gateway                  | `true`                    |
| `tls.secretName`                                  | If `tls.selfSigned` is false, then the API-Gateway will use this secret to obtain the certificate for downstream connections | `""`                      |
| `services.ca.aboutToExpire`                       | Number of days until a Certificate or CA is labeled as `About To expire`                                                     | `90`                      |
| `services.ca.periodicScan.enabled`                | Activate the Periodic Scan system                                                                                            | `true`               |
| `services.ca.periodicScan.cron`                   | Cron expression at which the Periodic Scan is launched                                                                       | `0 * * * *`               |
| `services.deviceManager.minimumReenrollmentDays`  | Minimum Reenrollment Days                                                                                                    | `100`                     |
| `services.database.username`                      | Databes Username                                                                                                             | `admin`                   |
| `services.database.password`                      | Databes Password                                                                                                             | `admin`                   |
| `services.alerts.smtp.from`                       | Display name for sender email address                                                                                        | `""`                      |
| `services.alerts.smtp.insecure`                   | Skip certificate validation for SMTP server                                                                                  | `false`                   |
| `services.alerts.smtp.enable_ssl`                 | Enable SSL connection for SMTP server                                                                                        | `true`                    |
| `services.alerts.smtp.username`                   | Username for accessing the SMTP server                                                                                       | `""`                      |
| `services.alerts.smtp.password`                   | Password for accessing for SMTP server                                                                                       | `""`                      |
| `services.alerts.smtp.host`                       | Hostname for the SMTP server                                                                                                 | `""`                      |
| `services.alerts.smtp.port`                       | Port for the SMTP server                                                                                                     | `25`                      |
| `services.awsConnector.enabled`                   | Enable the AWS Connector Deployment                                                                                          | `false`                   |
| `services.awsConnector.name`                      | Display name of the connector                                                                                                | `"AWS default connector"` |
| `services.awsConnector.aws.accessKeyId`           | Access key ID to access AWS via SDK                                                                                          | `""`                      |
| `services.awsConnector.aws.secretAccessKey`       | Secret access key to access AWS via SDK                                                                                      | `""`                      |
| `services.awsConnector.aws.defaultRegion`         | Default region for for accessing AWS via SDK                                                                                 | `""`                      |
| `services.awsConnector.aws.sqs.inboundQueueName`  | SQS Queue to listen events from AWS                                                                                          | `"lamassuResponse"`       |
| `services.awsConnector.aws.sqs.outbountQueueName` | SQS Queue to publish all cloud events                                                                                        | `""`                      |
| `simulationTools.enabled`                         | Enable simulation tools                                                                                                      | `false`                   |

### External OIDC Configuration

By default the helm chart deploys keycloak as the IAM provider, but it can be disabled and use your own IAM provider based on the OIDC protoco. Start by creating the new values file named `external-oidc.yml` to use by helm while installing:

1. The first step is disabling keycloak in order to aliviate the kubernete load:

  ```yaml
  services:
    keycloak:
      enabled: false
  ```

2. Navigate to your IAM's OIDC Well Known URL /.well-known/openid-configuration. For the `jwksUrl` yaml field, use the `jwks_uri` field from the well-known. Also for the `authorizationEndpoint` obtain the `authorization_endpoint` value by your ODIC Provider:

  ```yaml
  auth: 
    oidc:
      frontend:
        authorizationEndpoint: https://dev.lamassu.io/auth/realms/lamassu/protocol/openid-connect/auth
      apiGateway:
        jwksUrl: https://dev.lamassu.io/auth/realms/lamassu/protocol/openid-connect/certs
  ```

3. Create a new Client in yout OIDC provider to be used by the UI. Bare in mind that the UI should be redirected to the **DOMAIN** variable. Your OIDC must allow such redirect for the frontend client.

4. Provide de Client ID to be used by the frontend in the `auth.oidc.frontend.clientId` variable.

5. The content of the `external-oidc.yml` values file should be:
  ```yaml
  services:
    keycloak:
      enabled: false
  auth: 
    oidc:
      frontend:
        clientId: frontend
        authorizationEndpoint: https://dev.lamassu.io/auth/realms/lamassu/protocol/openid-connect/auth
      apiGateway:
        jwksUrl: https://dev.lamassu.io/auth/realms/lamassu/protocol/openid-connect/certs
  ```

### External Postgres Configuration