#!/bin/bash

helm repo add metallb https://metallb.github.io/metallb
helm upgrade --install metallb metallb/metallb
echo "sleeping for 30sec cuz i need to move this to flux"
sleep 30
kubectl apply -f files/manifests/metallb-addresses.yaml
