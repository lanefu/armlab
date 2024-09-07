#!/bin/bash

#cilium uninstall
ansible-playbook playbooks/kubevirt/provision_kubevirt_test.yml -i inventory/test.yml -e k3s_state=stopped
ansible-playbook playbooks/kubevirt/provision_kubevirt_test.yml -i inventory/test.yml -e k3s_state=uninstalled
ansible milddragon -i inventory/test.yml -m command -a 'nft flush ruleset' --become
##fixme delete /opt/cni/bin contents
ansible milddragon -i inventory/test.yml -m file -a 'path=/opt/cni/bin state=absent' --become
