#!/bin/bash

echo forget about all those old hosts
for host in ksmall-1 ksmall-2 ksmall-3 kmedium-1 kmedium-2 kmedium-3; do
  ssh-keygen -R ${host}
done

ansible-playbook playbooks/provision_k8s_nodes.yml -e @vars/local.yml -u root
#sleep on mac is stupid
SLEEP_MIN=2
echo "## wait ${SLEEP_MIN} min for cloud-init dance"
SLEEP_SEC=$(echo "${SLEEP_MIN} * 60" | bc)
sleep ${SLEEP_SEC}
ansible k8s_nodes -m ping
#ansible-playbook playbooks/update_k8s_nodes.yml --become
ansible-playbook playbooks/provision_k8s_cluster.yml --become
echo fetch kubeconfig
./scripts/fetch_kubeconfig.sh ksmall-1
export KUBECONFIG="$(pwd)/kubeconfig"
kubectl get nodes
scripts/install_kube-vip_arp.sh
kubectl -n kube-system get pods
kubectl apply -f https://raw.githubusercontent.com/inlets/inlets-operator/master/contrib/nginx-sample-deployment.yaml -n default
kubectl expose deployment nginx-1 --port=80 --type=LoadBalancer -n default --load-balancer-ip=172.17.20.41
kubectl get services
