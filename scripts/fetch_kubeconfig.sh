#!/bin/bash

## temporary script.. really should be using kube-vip and ansible and setting a hostname etc

HOST=${1}

if [[ -z ${HOST} ]]; then
	echo "provide host target as paramter"
	exit 1
fi

ssh -o StrictHostKeyChecking=accept-new ${HOST} "sudo cat /etc/rancher/k3s/k3s.yaml" | sed -e "s/https:\/\/127.0.0.1/https:\/\/${HOST}/" > kubeconfig
