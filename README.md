# armlab

clean sheet quick and dirty k8s and virt lab on some performant SBCs

## getting started

This repo is meant to be the ansible project directory.. or close to it plus documentation.. Trying to leverage off-the-shelf roles when possible. Other roles will via the [lanefu armlab collection](https://github.com/lanefu/ansible-collection-armlab.git)

There's plenty of other things in repo besides what is in readme.. this is kind of a living work space for me.

### environment setup

there are better ways, but this way for now... `.gitignore` has been preconfigured to use namedspace ansible home `.ansible/` and `venv` used in the example.

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
and worker nodes. Shared VM defaults now live in `vars/armlab_vm_defaults.yml`; use
`vars/local.yml` only for host-specific overrides.

#### notes for me

`ansible-playbook playbooks/provision_k8s_nodes.yml -e @vars/local.yml`

### destroy_k8s_nodes.yml

Destroy the VMs Above

### provision_k8s_cluster.yml

Bootstrap a k3s cluster

### provision_vm.yml

playbook to deploy a single VM

## scripts

I love ansible, but I'm not a purist. I'm extremely prone to lots of wrapper scripts as I experiment with things.
You'll see me even chain lots of ansible playbooks and commands in my scripts.

Note: you might see me `source` local config files where I have some "private" configuration values I did't want to upload.. They typically are just defining vars used directly in the script. Easy for you to recreate.

Interesting things in my scripts folder:

- `scripts/big_bang.sh` - soup to nuts deployment of my test k3s cluster from VM creation to fluxcd installation. Good one to look at
- `scripts/1password_connect_prep.sh` - seeds the `external-secrets` namespace with 1Password Connect credentials and token data
  - `apply` mode is for repeated bootstrap runs with `OP_SERVICE_ACCOUNT_TOKEN`
  - `init` mode is the one-time Connect setup path for when you create or rotate the Connect server
  - `rotate-token` reissues the Connect token and reseeds Kubernetes
  - `EMPIRE/scripts/armlab_big_bang.sh` will source `EMPIRE/.env` if it exists
  - put `OP_SERVICE_ACCOUNT_TOKEN=...` in that env file and keep it `chmod 600`
  - example:
    ```bash
    OP_SERVICE_ACCOUNT_TOKEN=opsa_...
    ```
- `scripts/fetch_kubeconfig.sh` - fetch kubeconfig from cluster cluster node and prepare for local use by updating API endpoint
- `scripts/kubevirt/` - scripts I used for experimenting with kubevirt bootstrapping. Currently targeted at x86 instead of ARM :P

## router experiments

Router-lab provisioning now renders cloud-init locally instead of depending on
the remote NoCloud URL. The router-lab playbook still lives in
`playbooks/provision_router_test.yml`, but the generated payload is now built
from the local workspace so the test-router path stays reproducible.

The `dual-router` topology adds a second experimental router and a downstream
peer so we can test DHCP handoff plus inter-router routing on the same lab
boundary.

The router experiment follows the live `lane` NetBox tenant and uses the
`net-test0` through `net-test3` prefix family:

- `192.168.100.0/24` on VLAN 1000 for the router transit segment
- `192.168.101.0/24` on VLAN 1001 reserved for the production router test1 segment
- `192.168.102.0/24` on VLAN 1002 for the second router LAN
- `192.168.103.0/24` on VLAN 1003 for the first router LAN and DHCP client

The routing ASN convention stays aligned with the home router stack:

- router side: `64512`
- armlab side: `64513`
