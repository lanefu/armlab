#!/bin/bash
set -euo pipefail

wait_for_crd() {
  local crd_name="$1"
  local timeout_seconds="${2:-300}"
  local start_epoch now_epoch

  start_epoch="$(date +%s)"
  while true; do
    if kubectl get crd "$crd_name" >/dev/null 2>&1; then
      kubectl wait --for=condition=Established "crd/${crd_name}" --timeout=30s >/dev/null
      return 0
    fi

    now_epoch="$(date +%s)"
    if (( now_epoch - start_epoch >= timeout_seconds )); then
      echo "timed out waiting for CRD ${crd_name}" >&2
      exit 1
    fi

    sleep 5
  done
}

wait_for_crd ciliumloadbalancerippools.cilium.io
wait_for_crd ciliumbgppeerconfigs.cilium.io
wait_for_crd ciliumbgpclusterconfigs.cilium.io
wait_for_crd ciliumbgpadvertisements.cilium.io

kubectl apply -f files/manifests/cilium-bgp.yaml
