#!/bin/bash

export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)

echo "uninstall cdi"
kubectl delete -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml
kubectl delete -f https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml

export CDI_VERSION=$(basename $(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest))
echo "uninstall kubevirt crd version ${CDI_VERSION}"
kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/${CDI_VERSION}/kubevirt-cr.yaml
echo "uninstall kubevirt operator version ${CDI_VERSION}"
kubectl delete -f https://github.com/kubevirt/kubevirt/releases/download/${CDI_VERSION}/kubevirt-operator.yaml
