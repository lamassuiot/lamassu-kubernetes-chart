# Lamassu on Kubernetes Helm Chart

## Overview

This is the Official Helm chart for installing and configuring Lamassu IoT on Kubernetes.

## Prerequisites - Kubernetes setup

* **Helm 3.2+**
* **Kubernetes 1.24** (This is the earliest tested version, it may work in previous versions)

It is also mandatory to have the following plugins enabled on the kubernetes cluster

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

## Verify

* Make sure your ingress controller has the SSL Passthrough enabled, otherwise the Lamassu chart won't work as expected. Refer to the Prerequisites > Ingress Controller section

* Depending on how the nginx ingress controller is installed, it may not pick the provisioned Ingress, and thus, no traffic will be routed through it. In those cases, run this commands and make sure your nginx ingress controller picks Lamassu's Ingress definitions:



## Usage

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

3. Install the helm chart. There are many ways to deploy Lamassu using this charts depending which subsystems are needed. Choose one of the following deployment modes

  **Core deployment**

  Make sure to use change the `domain` variable as well as the `storageClassName` (this can be obtained running `kubectl get sc`)

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

  **Core deployment + Alerts with email/SMTP**

  The alerts service is automatically deployed, but it needs some information to connect with an external SMTP server, see the Variables section for more information on how to configure this service

  ```bash
  helm install lamassu . --create-namespace -n $NS \
  --set domain=dev.lamassu.io \
  --set storageClassName=local-path \
  --set debugMode=true \
  --set services.alerts.smtp.from="lamassu-alerts@lamassu.io" \
  --set services.alerts.smtp.username="lamassu-alerts@lamassu.io"
  ```

  **Core deployment + AWS Connector**

  The AWS connector can also be deployed using the following command. Please note that it is required to provision the AWS resources from [https://github.com/lamassuiot/lamassu-aws-connector]()

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
## Configuration

### External OIDC Configuration

#### General Solution
!!! note
        The configuration down below, assumes that the `domain` variable is set to `dev.lamassu.io`. Change this value accordingly.

##### Authentication 

By default the helm chart deploys keycloak as the IAM provider, but it can be disabled and use your own IAM provider based on the OIDC protocol. Start by creating the new values file named `external-oidc.yml` to use by helm while installing:

1. The first step is disabling keycloak in order to alleviate the kubernetes load:

```yaml
services:
   keycloak: 
     enabled: false
```


2. The authority endpoint is an endpoint used for authentication in order to allow access to different clients. For the purpose of defining the right values, navigate to your IAM's  authority OIDC Well Known URL. The URL should be the authority endpoint concatenated with `/.well-known/openid-configuration`. 
 ```
EXAMPLE
auhtority: https://dev.lamassu.io/auth/realms/lamassu
auhtority oidc well-known: https://dev.lamassu.io/auth/realms/lamassu/.well-known/openid-configuration
 ```


3. For the `jwksUrl` yaml field, use the `jwks_uri` field from the well-known JSON.:
```yaml
auth:
  oidc:
    frontend:
      authority: https://dev.lamassu.io/auth/realms/lamassu
    apiGateway:
      jwksUrl: https://dev.lamassu.io/auth/realms/lamassu/protocol/openid-connect/certs
```

4. Create a new Client in your OIDC provider to be used by the UI. Configure your OIDC frontend client with the following options:
	`redirect_uri` (may be referred also as  `callback URLs`):  https://dev.lamassu.io
	`logout_uri` (may be referred also as  `sign out URLs`):  https://dev.lamassu.io/loggedout
	
5. Provide the Client ID to be used by the frontend in the `auth.oidc.frontend.clientId` variable.

6. The content of the `external-oidc.yml` values file should be:
```yaml
services: 
   keycloack:
      enabled: false
autn:
  oidc:
     frontend:
       clientId: frontend
       authority: https://dev.lamassu.io/auth/realms/lamassu
    apiGateway:
      jwksUrl: https://dev.lamassu.io/auth/realms/lamassu/protocol/openid-connect/certs
```

##### Authorisation

Make sure that the OIDC provider generates JWT with some claim including the user's roles or groups. We will be mapping those values to Lamssu's authorisation service by mapping the appropriate token claim.

This example assumes that the token has a clame named `user_roles` witch lists the roles the user has. This claim might include the `administrator` role or/and `viewer` role. To configure Lamssu to use this information add the following section to your `external-oidc.yml`:

```yaml
auth:
  authorization:
    rolesClaim: "user_roles"
    roles:
      admin: administrator
      operator: viewer
```

##### Authentication and Authorisation

The final version of the `external-oidc.yml`  values file should look similar to this one:

```yaml
services: 
  keycloack:
    enabled: false
autn:
  oidc:
     frontend:
       clientId: frontend
       authority: https://dev.lamassu.io/auth/realms/lamassu
    apiGateway:
      jwksUrl: https://dev.lamassu.io/auth/realms/lamassu/protocol/openid-connect/certs
  authorization:
    rolesClaim: "user_roles"
    roles:
      admin: administrator
      operator: viewer
```


#### Using AWS Cognito

In the case we will be using AWS Cognito as the external OIDC provider. It is assumed that you already have a provisioned cognito user pool (refer to https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html).

##### Authentication

Go to the already created User pool

1. In the selected App Integration > Create App Client:
	- Select `Public client`
	- App client name: `lamassu` 
	- Allowed callback URLs: `https://dev.lamassu.io` 
	- Allowed sign-out URLs: `https://dev.lamassu.io/loggedout` 
	
2. Go to App Integration > Domain > Actions > Create Cognito Domain. Provide a unique value in the popup window (this value must be unique in the entire AWS Region). 

3. Create the Helm values file named `aws-cognito-oidc.yml`  and replace the  `COGNIT_AWS_REGION`, `COGNITO_USER_POOL_ID` and `COGNITO_HOSTED_UI` accordingly.

```yaml
services:
  keycloack:
    enabled: false
auth:
  oidc:
    frontend: 
      clientId: lamassu
      authority: https://cognito-idp.<COGNIT_AWS_REGION>.amazonaws.com/<COGNITO_USER_POOL_ID>
      awsCognito: 
        enabled: true
        hostedUiDomain: "<COGNITO_HOSTED_UI>"
  apiGateway:
    jwksUrl: https://cognito-idp.<COGNIT_AWS_REGION>.amazonaws.com/<COGNITO_USER_POOL_ID>/.well-known/jwks.json 
```

##### Authorisation

Cognito doesn't have a dedicated roles section. The authorisation mechanism can be achieves using cognito's groups system. 

1. Create two groups, one named `pki-admin` and another one called `pki-operator` and assign your users into those groups.
2. Edit the previous values file as follows:

```yaml
auth:
  authorization:
    rolesClaim: "cognito:groups"
    roles:
      admin: pki-admin
      operator: pki-operator
```

##### Authentication and Authorisation 

The final version of the `aws-cognito-oidc.yml` values file should look similar to this one:

```yaml
services:
  keycloack:
    enabled: false
auth:
  oidc:
    frontend: 
      authority: https://cognito-idp.<COGNIT_AWS_REGION>.amazonaws.com/<COGNITO_USER_POOL_ID>
      clientId: lamassu
      awsCognito: 
        enabled: true
        hostedUiDomain: "<COGNITO_HOSTED_UI>"
  apiGateway:
    jwksUrl: https://cognito-idp.<COGNIT_AWS_REGION>.amazonaws.com/<COGNITO_USER_POOL_ID>/.well-known/jwks.json
  authorization:
    rolesClaim: "cognito:groups"
    roles:
      admin: pki-admin
      operator: pki-operator  
```

### External Postgres Configuration

## Clean uninstall

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
