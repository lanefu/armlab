#!/bin/bash

##check for crew
kubectl krew version
if [ $? -eq 1 ]; then
  echo "need to install krew see:"
  echo "https://krew.sigs.k8s.io/docs/user-guide/setup/install/"
  exit 1
fi

kubectl virt version
if [ $? -eq 1 ]; then
  echo "install virt plugin"
  kubectl krew install virt
fi

export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
echo "install kubevirt operator version ${VERSION}"
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml

#enable nested virtualizaiton
#kubectl -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"developerConfiguration":{"useEmulation":true}}}}'

echo "install kubevirt crds"
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml

echo "wait for virt-operator to be available"
kubectl wait --for=condition=Available -n kubevirt deployment/virt-operator

echo "wait for virt-api to be available"
until kubectl wait --for=condition=Available -n kubevirt deployment/virt-api; do
  sleep 10 # gotta wait for deployment to be defined
done
kubectl get pods -n kubevirt

echo "install kubevirt cdi"
export CDI_VERSION=$(basename $(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest))
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$CDI_VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$CDI_VERSION/cdi-cr.yaml

##check for crew
kubectl krew version
if [ $? -eq 1 ]; then
  echo "need to install krew see:"
  echo "https://krew.sigs.k8s.io/docs/user-guide/setup/install/"
  exit 1
fi

#set feature gates

kubectl apply -f files/manifests/kubevirt/config/feature_gates.yaml --server-side

#install multus

kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml

function install_mactap_cni() {
  #install mactap-cni in default
  kubectl apply -f https://raw.githubusercontent.com/kubevirt/macvtap-cni/main/manifests/macvtap.yaml

  #setup basic bridge requiremnets
  kubectl apply -f files/manifests/kubevirt/mactap

  #create mactap binding
  kubectl patch kubevirts -n kubevirt kubevirt --type=json -p='[{"op": "add", "path": "/spec/configuration/network",   "value": {
            "binding": {
                "macvtap": {
                    "domainAttachmentType": "tap"
                }
            }
        }}]'
}

echo done for now
