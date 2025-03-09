#!/bin/bash

if [[ -z ${1} ]]; then
  echo "error specify config file name"
  echo "example:"
  echo "  bootstrap_flux.sh mycluster_flux.conf"
  exit 1
fi

FLUX_CONFIG="${1}"

source ${FLUX_CONFIG}

flux bootstrap git -s \
  --url=${FLUX_REPO_URL} \
  --branch="${FLUX_BRANCH}" \
  --private-key-file="${FLUX_PRIVATE_KEY_FILE}" \
  --path="${FLUX_PATH}" \
  --network-policy=false \
  --verbose
