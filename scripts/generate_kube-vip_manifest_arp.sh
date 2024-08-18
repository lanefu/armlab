#!/bin/bash

export VIP=172.17.20.40
export INTERFACE=enp1s0
export KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")

KUBE_VIP_CMD="docker run --network host --rm ghcr.io/kube-vip/kube-vip:$KVVERSION"
alias kube-vip="${KUBE_VIP_CMD}"

${KUBE_VIP_CMD} manifest daemonset \
  --interface $INTERFACE \
  --address $VIP \
  --inCluster \
  --taint \
  --controlplane \
  --services \
  --arp \
  --leaderElection \
  --servicesElection yes \
  --enableNodeLabeling yes
