# lamassu

![Version: 2.5.3](https://img.shields.io/badge/Version-2.5.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.5.1](https://img.shields.io/badge/AppVersion-2.5.1-informational?style=flat-square)

PKI for Industrial IoT for Kubernetes

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| lamassuiot |  |  |

## Source Code

* <https://github.com/lamassuiot>
* <https://github.com/lamassuiot/lamassu-kubernetes-chart>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| amqp.hostname | string | `""` | Hostname for the AMQP server |
| amqp.password | string | `""` | Password to be used to authenticate with the AMQP server |
| amqp.port | int | `5672` | Port for the AMQP server |
| amqp.tls | bool | `false` | Enable AMQP over TLS (aka AMPQS) |
| amqp.username | string | `""` | Username to be used to authenticate with the AMQP server |
| auth.authorization.roles.admin | string | `"pki-admin"` | Role association to be used to authorize the user as LAMASSU's admin |
| auth.authorization.roles.operator | string | `"operator"` | Role association to be used to authorize the user as LAMASSU's operator |
| auth.authorization.rolesClaim | string | `"realm_access.roles"` | Claim to use to find and filter the user's roles |
| auth.oidc.apiGateway.jwksUrl | string | `"https://auth:8443/auth/realms/lamassu/protocol/openid-connect/certs"` | URL pointing to the issuer's public key set to validate the JWT tokens. |
| auth.oidc.frontend.authority | string | `"https://${window.location.host}/auth/realms/lamassu"` | URL pointing to the OIDC provider's base path to build the OIDC well-known URL (This is the complete URL preceding the "/.well-known/openid-configuration" URL). Can be a JS expression |
| auth.oidc.frontend.awsCognito.enabled | bool | `false` | Enable AWS Cognito as the OIDC provider for the frontend |
| auth.oidc.frontend.awsCognito.hostedUiDomain | string | `""` | AWS Cognito Hosted UI Domain |
| auth.oidc.frontend.clientId | string | `"frontend"` | Client ID to be used as the OIDC client for the frontend |
| debugMode | bool | `true` |  |
| global.imagePullPolicy | string | `"Always"` |  |
| ingress.annotations | string | `""` | Annotations to be added to the Ingress resource |
| ingress.enabled | bool | `true` |  |
| ingress.hostname | string | `"dev.lamassu.io"` | Hostname to be used for the Ingress resource to route all incoming traffic to the API Gateway |
| postgres.hostname | string | `""` | Hostname for the PostgreSQL server |
| postgres.password | string | `""` | Password to be used to authenticate with the PostgreSQL server |
| postgres.port | int | `5432` | Port for the PostgreSQL server |
| postgres.username | string | `""` | Username to be used to authenticate with the PostgreSQL server |
| service.nodePorts.apiGateway | int | `nil` | Node port for the HTTP port from the API Gateway service |
| service.nodePorts.apiGatewayTls | int | `nil` | Node port for the HTTP port from the API Gateway service |
| service.type | string | `"ClusterIP"` |  |
| services.alerts.image | string | `"ghcr.io/lamassuiot/lamassu-alerts:2.5.1"` | Docker image for the Alerts component |
| services.alerts.smtp_server.enable_ssl | bool | `true` | use TLS for the SMTP connection |
| services.alerts.smtp_server.from | string | `""` | email address to use as the sender of the alerts |
| services.alerts.smtp_server.host | string | `""` | SMTP server hostname |
| services.alerts.smtp_server.insecure | bool | `false` | skip TLS verification |
| services.alerts.smtp_server.password | string | `""` | SMTP server password |
| services.alerts.smtp_server.port | int | `25` | SMTP server port |
| services.alerts.smtp_server.username | string | `""` | SMTP server username |
| services.awsConnector.connectorID | string | `"aws.<account_id>"` | AWS IoT Connector ID. It is strongly recommended to use the aws.<account_id> format |
| services.awsConnector.credentials.accessKeyId | string | `""` | AWS Access Key ID |
| services.awsConnector.credentials.defaultRegion | string | `""` | AWS Region |
| services.awsConnector.credentials.secretAccessKey | string | `""` | AWS Secret Access Key |
| services.awsConnector.enabled | bool | `false` | Enable the AWS IoT Connector |
| services.awsConnector.image | string | `"ghcr.io/lamassuiot/lamassu-aws-connector:2.5.1"` | Docker image for the AWS Connector component |
| services.ca.domain | string | `"dev.lamassu.io"` | Domain to be used while signing/generating new CAs and certificates |
| services.ca.engines.awsKms | string | `nil` |  |
| services.ca.engines.awsSecretsManager | string | `nil` |  |
| services.ca.engines.defaultEngineID | string | `"golang-1"` | Default engine ID to be used for the CA component |
| services.ca.engines.golang[0].id | string | `"golang-1"` |  |
| services.ca.engines.golang[0].metadata.prod-ready | string | `"false"` |  |
| services.ca.engines.golang[0].storage_directory | string | `"/data"` |  |
| services.ca.engines.hashicorpVault | string | `nil` |  |
| services.ca.engines.pkcs11 | string | `nil` |  |
| services.ca.image | string | `"ghcr.io/lamassuiot/lamassu-ca:2.5.1"` | Docker image for the CA component |
| services.ca.monitoring.frequency | string | `"* * * * *"` | Frequency to check the CA's health status uses CRON syntax. Can also be specified at a "second" level by adding one extra term |
| services.deviceManager.image | string | `"ghcr.io/lamassuiot/lamassu-devmanager:2.5.1"` | Docker image for the Device Manager component |
| services.dmsManager.image | string | `"ghcr.io/lamassuiot/lamassu-dmsmanager:2.5.1"` | Docker image for the DMS Manager component |
| services.keycloak.adminCreds.password | string | `"admin"` | Password for the Keycloak admin user (used by the master realm) |
| services.keycloak.adminCreds.username | string | `"admin"` | Username for the Keycloak admin user (used by the master realm) |
| services.keycloak.enabled | bool | `true` | If disabled, the internal Keycloak authentication component is disabled. An external one must be provided through the `auth.oidc` properties |
| services.keycloak.image | string | `"ghcr.io/lamassuiot/keycloak:2.1.0"` | Docker image for keycloak component |
| services.openPolicyAgent.image | string | `"openpolicyagent/opa:0.37.1-envoy"` | Docker image for the Open Policy Agent component |
| services.openPolicyAgent.remLogger.image | string | `"ghcr.io/lamassuiot/opa-rem-logger:2.1.0"` | Docker image for the Remote Logger component |
| services.ui.image | string | `"ghcr.io/lamassuiot/lamassu-ui:2.5.2"` | Docker image for the UI component |
| services.va.image | string | `"ghcr.io/lamassuiot/lamassu-va:2.5.1"` | Docker image for the VA component |
| tls.certManagerOptions.clusterIssuer | string | `""` | CertManager ClusterIssuer to use to sign the certificate for the API Gateway.  |
| tls.certManagerOptions.duration | string | `"2160h"` | Duration for the certificate to be valid |
| tls.certManagerOptions.issuer | string | `""` | CertManager Issuer to use to sign the certificate for the API Gateway. Ignored if `clusterIssuer` is set. If left empty, a self signed certificate will be used. |
| tls.externalOptions.secretName | string | `""` | Secret name for the TLS certificate to be used for the API Gateway (the secret at least must have `tls.crt` and `tls.key` keys) |
| tls.type | string | `"certManager"` | TLS certificate provider to use for the API Gateway. Allowed values are: `certManager`, `external` |

