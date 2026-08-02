#!/bin/bash
set -euo pipefail

# Deliberately separate from install_cilium_bgp.sh. This creates only the
# opt-in AWS worker policy; it does not alter the LAN-side BGP objects.
if [[ -n "${ARMLAB_EMPIRECTL:-}" ]]; then
  "$ARMLAB_EMPIRECTL" kubectl armlab apply -f files/manifests/cilium-bgp-aws-spot.yaml
else
  kubectl apply -f files/manifests/cilium-bgp-aws-spot.yaml
fi
