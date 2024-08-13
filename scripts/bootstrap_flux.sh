#!/bin/bash

source armlab_flux.conf

flux bootstrap git \
  --url=${FLUX_REPO_URL} \
  --branch="${FLUX_BRANCH}" \
  --private-key-file="${FLUX_PRIVATE_KEY_FILE}" \
  --path="${FLUX_PATH}" \
  --network-policy=false \
  --verbose
