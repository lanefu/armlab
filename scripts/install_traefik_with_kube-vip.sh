#!/bin/bash

VIP=172.17.20.42
NAMESPACE=default

#helm repo add traefik https://helm.traefik.io/traefik
#helm repo update

helm upgrade --install traefik traefik/traefik \
  --namespace ${NAMESPACE} \
  --set additional.checkNewVersion=false \
  --set additional.sendAnonymousUsage=false \
  --set dashboard.enable=true \
  --set ingressRoute.dashboard.enabled=true \
  --set service.spec.loadBalancerIP=${VIP}
