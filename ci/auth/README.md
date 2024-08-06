### Create theme ZIP and upload to Kubernetes

```bash
cd themes/theme
tar -czf lamassu-v2-theme.tar lamassu.v2
kubectl delete configmap -n lamassu-dev keycloak-lamassu-theme
kubectl create configmap -n lamassu-dev keycloak-lamassu-theme --from-file ./lamassu-v2-theme.tar
cd ../..
```

```bash
```

```bash
kubectl create configmap -n lamassu-dev keycloak-post-init

```

### Deploy Keycloak

```bash
  cat >keycloak-values.yaml <<"EOF"
postgres:
  enabled: false
externalDatabase:
  host: "postgres"
  port: 5432
  user: admin
  password: MFiO863IXSBKjQRtXn2CFqUg@T$uHN
  database: aurth

extraVolumes:
  - name: shared-keycloak-volume
    emptyDir: {}
  - name: theme-volume
    configMap:
      name: keycloak-lamassu-theme

extraVolumeMounts:
  - mountPath: /opt/bitnami/keycloak/themes/
    name: shared-keycloak-volume

initContainers:
- name: init-customtheme
  image: busybox:1.28
  # command: ['sh', '-c', 'ls -lisah /CustomTheme'] 
  command: ['sh', '-c', 'cp -rL /CustomTheme/lamassu-v2-theme.tar /shared && cd /shared/ && tar -xvf lamassu-v2-theme.tar && rm -rf lamassu-v2-theme.tar && ls -lisah /shared/']
  volumeMounts:
  - mountPath: /shared
    name: shared-keycloak-volume      
  - mountPath: /CustomTheme
    name: theme-volume

extraEnvVars:
- name: KC_SPI_THEME_LOGIN_THEME
  value: lamassu.v2

service:
  type: NodePort
  nodePorts: 
    http: 30080
EOF

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-keycloak -n lamassu-dev bitnami/keycloak --version 21.3.1 -f keycloak-values.yaml
```

helm uninstall my-keycloak -n lamassu-dev
kubectl delete configmap -n lamassu-dev keycloak-lamassu-theme
