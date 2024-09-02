#!/bin/bash
set -e

source armlab_kubevirt_test.conf

ansible-playbook playbooks/kubevirt/provision_kubevirt_test.yml

./scripts/fetch_kubeconfig.sh ${PRIMARY_HOST_IP}
export KUBECONFIG=$(pwd)/kubeconfig

echo "wait for cluster to bootstrap before cilium"
sleep 30
cilium install

kubectl get pods --all-namespaces
