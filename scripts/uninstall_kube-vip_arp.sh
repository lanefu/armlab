#!/bin/bash

#./scripts/generate_kube-vip_manifest_arp.sh > files/manifests/kube-vip_daemonset.yaml

kubectl delete -f files/manifests/kube-vip_daemonset.yaml
kubectl delete -f https://kube-vip.io/manifests/rbac.yaml
