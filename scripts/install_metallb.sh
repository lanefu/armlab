#!/bin/bash

helm repo add metallb https://metallb.github.io/metallb
helm upgrade --install metallb metallb/metallb
n=0
until [ "$n" -ge 15 ]; do
  kubectl apply -f files/manifests/metallb-addresses.yaml && break # substitute your command here
  n=$((n + 1))
  sleep 10
  echo "retrying appyly. i need to move this to flux"
done
