#!/bin/bash

dist=
kube=
kubectl="kubectl"
helm="helm"

DOMAIN=dev.lamassu.io
DOMAIN_OVERRIDE=false
NAMESPACE=lamassu-dev
NAMESPACE_OVERRIDE=false
OFFLINE=false
NON_INTERACTIVE=false

POSTGRES_USER=admin
POSTGRES_PWD=$(
    shuf -er -n30  {A..Z} {a..z} {0..9} {.,@,$} | tr -d '\n'
    echo
)
RABBIT_USER=admin
RABBIT_PWD=$(
    shuf -er -n30  {A..Z} {a..z} {0..9} {.,@,$} | tr -d '\n'
    echo
)

KEYCLOAK_USER=admin
KEYCLOAK_PWD=$(
    shuf -er -n30  {A..Z} {a..z} {0..9} {.,@,$} | tr -d '\n'
    echo
)

OFFLINE_HELMCHART_LAMASSU=""
OFFLINE_HELMCHART_RABBITMQ=""
OFFLINE_HELMCHART_POSTGRES=""


function main() {
    init

    process_flags "$@"

    detect_distribution
    if [ $dist == "microk8s" ]; then
        kube="microk8s"
    fi

    if [ "$OFFLINE" = true ]; then
        echo -e "${ORANGE}Offline mode enabled. Images must be already imported${NOCOLOR}" 

        if [ "$OFFLINE_HELMCHART_LAMASSU" = "" ]; then
            echo -e "\n${RED}Lamassu helm chart path is empty${NOCOLOR}"
            exit 1
        fi
        if [ "$OFFLINE_HELMCHART_RABBITMQ" = "" ]; then
            echo -e "\n${RED}RabbitMQ helm chart path is empty${NOCOLOR}"
            exit 1
        fi
        if [ "$OFFLINE_HELMCHART_POSTGRES" = "" ]; then
            echo -e "\n${RED}Postgres helm chart path is empty${NOCOLOR}"
            exit 1
        fi
    else
        echo -e "${ORANGE}ONLINE MODE ENABLED${NOCOLOR}" 
    fi

    echo -e "${BLUE}=== Installing Lamassu IoT using Fast Lane ===${NOCOLOR}"
    echo -e "\n${BLUE}1) Dependencies checking${NOCOLOR}"
    check_dependencies
    echo -e "\n${BLUE}2) Provide minimal config info${NOCOLOR}"
    request_config_data
    echo -e "\n${BLUE}3) Create ${NAMESPACE} namespace${NOCOLOR}"
    create_kubernetes_namespace
    echo -e "\n${BLUE}4) Install PostgreSQL${NOCOLOR}"
    install_postgresql
    echo -e "\n${BLUE}5) Install RabbitMQ${NOCOLOR}"
    install_rabbitmq
    echo -e "\n${BLUE}6) Install Lamassu IoT. It may take a few minutes${NOCOLOR}"
    install_lamassu
    echo -e "\n${BLUE}7) Patch ingress for Lamassu IoT${NOCOLOR}"
    if [ $dist == "microk8s" ]; then
        microk8s_patch_lamassu
    fi
    if [ $dist == "k3s" ]; then
        k3s_patch_lamassu
    fi
    final_instructions
}

function usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo " -h, --help              Display this help message"
    echo " -n, --non-interactive   Enable non-interactive mode. Credentials for Keycloak, Postgres and RabbitMQ will be auto generated"
    echo " -ns, --namespace        Kubernetes Namespace where LAMASSU will be deployed"
    echo " -d, --domain            Domain to be set while deploying LAMASSU"
    echo " --offline               Offline mode enabled. Use local helm charts (--helm-chart-rabbitmq, --helm-chart-postgres and --helm-chart-lamassu flags will be required)"
    echo " --helm-chart-lamassu    (Only needed while using --offline) Path to the Lamassu helm chart (.tgz format)"
    echo " --helm-chart-postgres   (Only needed while using --offline) Path to the Posgtres helm chart (.tgz format)"
    echo " --helm-chart-rabbitmq   (Only needed while using --offline) Path to the RabbitMQ helm chart (.tgz format)"
}

function has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

function extract_argument() {
  echo "${2:-${1#*=}}"
}


function process_flags() {
    while [ $# -gt 0 ]; do
        case $1 in
        -h | --help)
            usage
            exit 0
            ;;
        --offline)
            OFFLINE=true
            ;;
         --helm-chart-lamassu)
              if ! has_argument $@; then
                echo -e "\n${RED}Lamassu Helm Chart not specified.${NOCOLOR}" >&2
                usage
                exit 1
            fi
            OFFLINE_HELMCHART_LAMASSU=$(extract_argument $@)

            shift
            ;;
         --helm-chart-postgres)
              if ! has_argument $@; then
                echo -e "\n${RED}Postgres Helm Chart not specified.${NOCOLOR}" >&2
                usage
                exit 1
            fi
            OFFLINE_HELMCHART_POSTGRES=$(extract_argument $@)

            shift
            ;;
         --helm-chart-rabbitmq)
              if ! has_argument $@; then
                echo -e "\n${RED}Rabbitmq Helm Chart not specified.${NOCOLOR}" >&2
                usage
                exit 1
            fi
            OFFLINE_HELMCHART_RABBITMQ=$(extract_argument $@)

            shift
            ;;
        -n | --non-interactive)
            NON_INTERACTIVE=true
            ;;
        -d | --domain*)
            if ! has_argument $@; then
                  echo -e "\n${RED}Domain not specified.${NOCOLOR}" >&2
                usage
                exit 1
            fi
            DOMAIN_OVERRIDE=true
            DOMAIN=$(extract_argument $@)

            shift
            ;;
            
        -ns | --namespace*)
            if ! has_argument $@; then
            echo -e "\n${RED}Namespace not specified.${NOCOLOR}" >&2
                usage
                exit 1
            fi
            NAMESPACE_OVERRIDE=true
            NAMESPACE=$(extract_argument $@)

            shift
            ;;
        *)
            echo -e "\n${RED}Invalid option: $1${NOCOLOR}" >&2
            usage
            exit 1
            ;;
        esac
        shift
    done
}

function final_instructions() {
    echo -e "${GREEN}=== Lamassu IoT has been installed in your Kubernetes instance ===${NOCOLOR}"
    echo -e "${BLUE}Please navigate to Keycloak console at https://${DOMAIN}/auth/admin${NOCOLOR}"
    echo -e "${BLUE}Use the provided Keycloak credentials ${KEYCLOAK_USER}/${KEYCLOAK_PWD}${NOCOLOR}"
    echo -e "${BLUE}Create a new user in the lamassu realm with pki-admin role and connect to https://${DOMAIN}${NOCOLOR}"
}

function k3s_patch_lamassu() {
    $kube $kubectl patch ing/api-gateway-https --namespace $NAMESPACE --type=json -p='[{"op": "add", "path": "/spec/ingressClassName", "value": "nginx" }]'
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}Lamassu IoT successfully patched${NOCOLOR}"
    else
        echo -e "\n${RED}Error applying patch on Lamassu IoT${NOCOLOR}"
        exit 1
    fi
}

function microk8s_patch_lamassu() {
    cat >>lamassu.yaml <<"EOF"
ingress:
  annotations: |
    kubernetes.io/ingress.class: "public"
EOF
    $kube $helm upgrade -n $NAMESPACE lamassu lamassuiot/lamassu -f lamassu.yaml
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}Lamassu IoT successfully patched${NOCOLOR}"
    else
        echo -e "\n${RED}Error applying patch on Lamassu IoT${NOCOLOR}"
        exit 1
    fi
}

function install_lamassu() {
    cat >lamassu.yaml <<"EOF"
domain: env.lamassu.domain
postgres:
  hostname: "postgresql"
  port: 5432
  username: "env.postgre.user"
  password: "env.postgre.password"

amqp:
  hostname: "rabbitmq"
  port: 5672
  username: "env.rabbitmq.user"
  password: "env.rabbitmq.password"
  tls: false
services:
  keycloak:
    enabled: true
    image: ghcr.io/lamassuiot/keycloak:2.1.0
    adminCreds:
      username: "env.keycloak.user"
      password: "env.keycloak.password"
EOF

    sed 's/env.lamassu.domain/'"$DOMAIN"'/' -i lamassu.yaml
    sed 's/env.postgre.user/'"$POSTGRES_USER"'/;s/env.postgre.password/'"$POSTGRES_PWD"'/' -i lamassu.yaml
    sed 's/env.rabbitmq.user/'"$RABBIT_USER"'/;s/env.rabbitmq.password/'"$RABBIT_PWD"'/' -i lamassu.yaml
    sed 's/env.keycloak.user/'"$KEYCLOAK_USER"'/;s/env.keycloak.password/'"$KEYCLOAK_PWD"'/' -i lamassu.yaml

    helm_path=lamassuiot/lamassu
    if [ "$OFFLINE" = false ]; then
        $kube $helm repo add lamassuiot http://www.lamassu.io/lamassu-helm/
    else 
        helm_path=$OFFLINE_HELMCHART_LAMASSU
    fi

    $kube $helm install -n $NAMESPACE lamassu $helm_path -f lamassu.yaml --wait

    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}Lamassu IoT installed${NOCOLOR}"
    else
        echo -e "\n${RED}Error installing Lamassu IoT${NOCOLOR}"
        exit 1
    fi
}

function install_rabbitmq() {
    helm_path=bitnami/rabbitmq
    if [ "$OFFLINE" = false ]; then
        $kube $helm repo add bitnami https://charts.bitnami.com/bitnami
    else 
        helm_path=$OFFLINE_HELMCHART_RABBITMQ
    fi

    $kube $helm repo update
    $kube $helm install rabbitmq $helm_path --version 12.6.0 -n $NAMESPACE --set fullnameOverride=rabbitmq --set auth.username=$RABBIT_USER --set auth.password=$RABBIT_PWD
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}RabbitMQ installed${NOCOLOR}"
    else
        echo -e "\n${RED}Error installing RabbitMQ${NOCOLOR}"
        exit 1
    fi
}

function install_postgresql() {

    cat >postgres.yaml <<"EOF"
fullnameOverride: "postgresql"
global:
  postgresql:
    auth:
      username: env.user
      password: env.password
primary:
  initdb:
    scripts:
      init.sql: |
        CREATE DATABASE auth;
        CREATE DATABASE alerts;
        CREATE DATABASE ca;
        CREATE DATABASE cloudproxy;
        CREATE DATABASE devicemanager;
        CREATE DATABASE dmsmanager;
EOF

    sed 's/env.user/'"$POSTGRES_USER"'/;s/env.password/'"$POSTGRES_PWD"'/' -i postgres.yaml

    helm_path=bitnami/postgresql
    if [ "$OFFLINE" = false ]; then
        $kube $helm repo add bitnami https://charts.bitnami.com/bitnami
    else 
        helm_path=$OFFLINE_HELMCHART_POSTGRES
    fi

    echo $helm_path

    $kube $helm install postgres $helm_path -n $NAMESPACE -f postgres.yaml --wait
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}PostgreSQL installed${NOCOLOR}"
    else
        echo -e "\n${RED}Error installing PostgreSQL${NOCOLOR}"
        exit 1
    fi
}

function create_kubernetes_namespace() {
    $kube $kubectl create ns $NAMESPACE
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}Namespace $NAMESPACE created${NOCOLOR}"
    else
        echo -e "\n${RED}Error creating namespace $NAMESPACE${NOCOLOR}"
        exit 1
    fi
}

function request_config_data() {
    if [ "$NON_INTERACTIVE" = false ]; then
        request_domain
        request_postgres_user
        request_postgres_pwd
        request_rabbit_user
        request_rabbit_pwd
        request_keycloak_user
        request_keycloak_pwd
        request_namespace
    else
        echo -e "${ORANGE}Non-interactive mode enabled. Credentials will be auto generated${NOCOLOR}" 
        if [ "$DOMAIN_OVERRIDE" = false ]; then
            echo -e "${ORANGE}Domain not provied. Default will be used: $DOMAIN${NOCOLOR}"
        fi
        if [ "$NAMESPACE_OVERRIDE" = false ]; then
            echo -e "${ORANGE}Namespace not provied. Default will be used: $NAMESPACE${NOCOLOR}"
        fi        
    fi
}

function request_domain() {
    echo -n "Lamassu IoT Domain ($DOMAIN): "
    read reqdomain
    if [ "$reqdomain" != "" ]; then
        DOMAIN=$reqdomain
    fi
}

function request_postgres_user() {
    echo -n "PostgreSQL admin user ($POSTGRES_USER): "
    read req
    if [ "$req" != "" ]; then
        POSTGRES_USER=$req
    fi
}

function request_postgres_pwd() {
    echo -n "PostgreSQL admin password ($POSTGRES_PWD): "
    read req
    if [ "$req" != "" ]; then
        POSTGRES_PWD=$req
    fi
}

function request_rabbit_user() {
    echo -n "RabbitMQ admin user ($RABBIT_USER): "
    read req
    if [ "$req" != "" ]; then
        RABBIT_USER=$req
    fi
}

function request_rabbit_pwd() {
    echo -n "RabbitMQ admin password ($RABBIT_PWD): "
    read req
    if [ "$req" != "" ]; then
        RABBIT_PWD=$req
    fi
}

function request_keycloak_user() {
    echo -n "Keycloak admin user ($KEYCLOAK_USER): "
    read req
    if [ "$req" != "" ]; then
        RABBIT_USER=$req
    fi
}

function request_keycloak_pwd() {
    echo -n "Keycloak admin password ($KEYCLOAK_PWD): "
    read req
    if [ "$req" != "" ]; then
        RABBIT_PWD=$req
    fi
}

function request_namespace() {
    echo -n "Kubernetes namespace ($NAMESPACE): "
    read req
    if [ "$req" != "" ]; then
        NAMESPACE=$req
    fi
}

function detect_distribution() {
    is_command_installed "microk8s"
    if [ $? -eq 0 ]; then
        dist="microk8s"
        echo -e "${GREEN}Microk8s detected${NOCOLOR}"
        return 0
    fi
    is_command_installed "k3s"
    if [ $? -eq 0 ]; then
        dist="k3s"
        echo -e "${GREEN}K3s detected${NOCOLOR}"
        return 0
    fi
    is_command_installed "kind"
    if [ $? -eq 0 ]; then
        dist="kind"
        echo -e "${GREEN}Kind detected - USE IT ONLY FOR TESTING${NOCOLOR}"
        return 0
    fi
    echo -e "${RED}No kubernetes distribution found${NOCOLOR}"
    exit 1
}

function check_dependencies() {
    exit_if_command_not_installed $dist
    if [ $dist == "k3s" ]; then
        exit_if_command_not_installed $kubectl
        exit_if_command_not_installed $helm
    fi

    if [ $dist == "microk8s" ]; then
        exit_if_kube_command_not_installed $kubectl
        exit_if_kube_command_not_installed $helm
        check_microk8s_minimum_requirements
    fi

}

function check_microk8s_minimum_requirements() {
    is_microk8s_addon_enabled helm
    is_microk8s_addon_enabled hostpath-storage
    is_microk8s_addon_enabled dns
    is_microk8s_addon_enabled ingress
    is_microk8s_addon_enabled cert-manager
}

function init() {
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    ORANGE='\033[0;33m'
    GREEN='\033[0;32m'
    NOCOLOR='\033[0m'
}

function is_command_installed() {
    if ! command -v "$1" &>/dev/null; then
        return 1
    else
        return 0
    fi
}

function exit_if_kube_command_not_installed() {
    if $kube $1 version &>/dev/null; then
        echo "✅ $1"
    else
        echo "$1: Addon not detected. Exiting"
        exit 1
    fi
}

function exit_if_command_not_installed() {
    is_command_installed "$1"
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "$1: Not detected. Exiting"
        exit 1
    fi
}

function is_microk8s_addon_enabled() {

    if [ $(microk8s status --a $1) == "enabled" ]; then
        echo "✅ $1 addon enabled"
    else
        echo "$1: Addon not enabled. Exiting"
        exit 1
    fi
}

main "$@"
