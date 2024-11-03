#!/bin/bash

echo "deploy debian masquerede vm"
kubectl apply -f files/manifests/kubevirt/debian/dv_debian_x86_64.yaml
kubectl apply -f files/manifests/kubevirt/debian/debian_vm1_pvc_x86_64.yaml
kubectl virt expose vmi debian-vm1 --name=debian-vm1-ssh --port=20222 --target-port=22 --type=NodePort

SSH_PORT=$(kubectl virt expose vmi debian-vm1 --name=debian-vm1-ssh --port=20222 --target-port=22 --type=NodePort)
kubectl get services

echo "VM1_SSH_PORT=${SSH_PORT}"

echo "deploy a bridged armbian VM"

kubectl apply -f files/manifests/kubevirt/bridge/bridge_attachment_definition.yaml
kubectl apply -f files/manfiest/kubevirt/armbian
