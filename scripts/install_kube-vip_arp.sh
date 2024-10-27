#!/bin/bash

# generation tool requires docker so lets just skip if it exists to same time
if [ ! -f files/manifests/kube-vip_daemonset.yaml ]; then
  ./scripts/generate_kube-vip_manifest_arp.sh >files/manifests/kube-vip_daemonset.yaml
fi

kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
kubectl apply -f files/manifests/kube-vip_daemonset.yaml
