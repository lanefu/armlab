#!/bin/bash

./scripts/generate_kube-vip_manifest_arp.sh > files/manifests/kube-vip_daemonset.yaml

kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
kubectl apply -f files/manifests/kube-vip_daemonset.yaml
