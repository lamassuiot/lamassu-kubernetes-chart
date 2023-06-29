docker build -f ci/auth/dockerfile -t ghcr.io/lamassuiot/keycloak:dev ci/auth
docker push ghcr.io/lamassuiot/keycloak:dev

docker build -f ci/toolbox/dockerfile -t ghcr.io/lamassuiot/toolbox:dev ci/toolbox
docker push ghcr.io/lamassuiot/toolbox:dev

docker build -f ci/opa-rem-logger/dockerfile -t ghcr.io/lamassuiot/opa-rem-logger:dev ci/opa-rem-logger
docker push ghcr.io/lamassuiot/opa-rem-logger:dev