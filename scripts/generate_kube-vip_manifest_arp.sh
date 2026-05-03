#!/bin/bash

if [[ -z ${VIP} ]]; then
  echo "set VIP before generating the kube-vip manifest"
  exit 1
fi

if [[ -z ${INTERFACE} ]]; then
  echo "set INTERFACE before generating the kube-vip manifest"
  exit 1
fi

KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")

KUBE_VIP_CMD="docker run --network host --rm ghcr.io/kube-vip/kube-vip:$KVVERSION"
alias kube-vip="${KUBE_VIP_CMD}"

${KUBE_VIP_CMD} manifest daemonset \
  --interface $INTERFACE \
  --address $VIP \
  --inCluster \
  --taint \
  --controlplane \
  --arp \
  --enableNodeLabeling yes
#  --leaderElection no \
#  --servicesElection no \
#  --services no \
