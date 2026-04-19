#!/bin/bash
set -euo pipefail

kubectl apply -f files/manifests/cilium-bgp.yaml
