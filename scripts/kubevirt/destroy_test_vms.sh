#!/bin/bash

echo "deploy debian masquerede vm"
kubectl delete -f files/manifests/kubevirt/debian_vm1_pvc_x86_64.yaml
kubectl delete -f files/manifests/kubevirt/dv_debian_x86_64.yaml

kubectl delete service debian-vm1
