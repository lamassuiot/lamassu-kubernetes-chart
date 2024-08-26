### Create theme ZIP and upload to Kubernetes

```
kubectl cp dist_keycloak/keycloak-theme-for-kc-22-and-above.jar -n lamassu-dev auth-keycloak-0:/extensions/lamassu-theme.jar -c init-custom-theme
```