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
