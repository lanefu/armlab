#!/bin/bash

# generating this needs docker, which is annoying, so only do it when the manifest is missing
if [ ! -f files/manifests/kube-vip_daemonset.yaml ]; then
  ./scripts/generate_kube-vip_manifest_arp.sh >files/manifests/kube-vip_daemonset.yaml
fi

kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
kubectl apply -f files/manifests/kube-vip_daemonset.yaml
