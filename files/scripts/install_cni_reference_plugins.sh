#!/bin/bash
export ARCH_CNI=$([ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)
export CNI_PLUGIN_VERSION=v1.5.1
mkdir -p /opt/cni/bin
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGIN_VERSION}/cni-plugins-linux-${ARCH_CNI}-${CNI_PLUGIN_VERSION}".tgz &&
  tar -C /opt/cni/bin -xzf cni-plugins.tgz --wildcards --no-anchored 'bridge'
