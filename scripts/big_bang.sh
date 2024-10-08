#!/bin/bash
set -e

CONTROL_NODE="ksmall-1"
VIP=172.17.20.40
NGINX_VIP=172.17.20.41
export ANSIBLE_INVENTORY=inventory/hosts.yml

echo forget about all those old hosts
for host in ksmall-1 ksmall-2 ksmall-3 kmedium-1 kmedium-2 kmedium-3; do
  ssh-keygen -R ${host}
done

ansible-playbook playbooks/provision_k8s_nodes.yml -e @vars/local.yml -u root
ansible-playbook playbooks/ping_k8s_nodes.yml -i inventory/hosts.yml
#ansible-playbook playbooks/update_k8s_nodes.yml --become

ansible-playbook playbooks/provision_k8s_cluster.yml --become
echo fetching kubeconfig
./scripts/fetch_kubeconfig.sh ${CONTROL_NODE}
export KUBECONFIG="$(pwd)/kubeconfig"

kubectl get nodes

./scripts/install_kube-vip_arp.sh
cilium install

kubectl -n kube-system get pods

kubectl apply -f https://raw.githubusercontent.com/inlets/inlets-operator/master/contrib/nginx-sample-deployment.yaml -n default
kubectl expose deployment nginx-1 --port=80 --type=LoadBalancer -n default --load-balancer-ip=${NGINX_VIP}

./scripts/install_traefik_with_kube-vip.sh
./scripts/bootstrap_flux.sh

echo change KUBECONFIG to VIP now that cilium bootstrapping is done
./scripts/fetch_kubeconfig.sh ${CONTROL_NODE} ${VIP}

./scripts/install_metallb.sh

kubectl get services --all-namespaces
curl 'http://echo.ktest.angrybear.com' | jq '.request.headers'
