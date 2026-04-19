#!/bin/bash

VIP=172.17.28.2
NAMESPACE=default

#helm repo add traefik https://helm.traefik.io/traefik
#helm repo update

helm upgrade --install traefik traefik/traefik \
  --namespace ${NAMESPACE} \
  --create-namespace \
  --set api.dashboard=true \
  --set ingressRoute.dashboard.enabled=true \
  --set service.spec.externalTrafficPolicy=Local \
  --set service.spec.loadBalancerClass=io.cilium/bgp-control-plane \
  --set service.spec.loadBalancerIP=${VIP}

kubectl label service traefik -n ${NAMESPACE} bgp.armlab.io/service=true --overwrite
