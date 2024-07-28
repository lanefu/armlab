# armlab
clean sheet quick and dirty k8s and virt lab on some performant SBCs

## getting started

This repo is meant to be the ansible project directory.. or close to it plus documentation..  Trying to leverage off-the-shelf roles when possible.  Other roles will via the [lanefu armlab collection](https://github.com/lanefu/ansible-collection-armlab.git)

### environment setup

there are better ways, but this way for now...  `.gitignore` has been preconfigured to use namedspace ansible home `.ansible/` and `venv` used in the example.

#### requirements

assume you have python3 and python3-venv installed

```
python3 -m venv venv
source venv/bin/activate
python3 -m pip install -r requirements.txt
ansible-galaxy install -r requirements.yml
ansible-galaxy install -r requirements-armlab.yml 
```

## playbooks

### cockpit_vmhost.yml 

Installs qemu, libvirt, and cockpit for deploying virtual machines

### provision_k8s_nodes.yml

Provision a pool of VMs on the VM hosts intended to be used later as k8s control plane
and worker nodes

#### notes for me 

`ansible-playbook playbooks/provision_k8s_nodes.yml -e @vars/local.yml`

### destroy_k8s_nodes.yml

Destroy the VMs Above

### provision_k8s_cluster.yml

Bootstrap a k3s cluster 

### provison_vm.yml

playbook to deploy a single VM
