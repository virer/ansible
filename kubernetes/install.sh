#!/bin/bash
###########

ansible-galaxy collection install  gaurav_gupta_gtm.ansible_kubeadm

cd ~
cp -r ~/.ansible/collections/ansible_collections/gaurav_gupta_gtm/ansible_kubeadm/roles ~/.ansible/

# Patch
sed -i 's#--pod-network-cidr#--service-cidr#g' ~/.ansible/roles/master/tasks/main.yml
sed -i 's/slave/worker/g' ~/.ansible/roles/node/README.md
sed -i 's/scommunity.general.modprobe/modprobe/g' ~/.ansible/collections/ansible_collections/gaurav_gupta_gtm/ansible_kubeadm/roles/runtime/crio_setup/tasks/main.yml


mkdir -m 750 ~/.ssh ~/group_vars
cat <<EOF> group_vars/all.yml
---
pod_network_cidr: "100.64.0.0/16"

# Network implementation('flannel', 'weave')
network: weave

# Container runtimes ('docker', 'crio')
container_runtime: crio

EOF

cat <<EOF> playbook.yml

- hosts: all
  connection: local
  gather_facts: false
  tasks:
  - name: keyscan remote machine key to host
    shell: ssh-keyscan {{ ansible_host }} >> "{{ lookup('env','HOME') }}/.ssh/known_hosts"
    register: known_hosts

- hosts: all
  connection: local
  gather_facts: false
  collections:
    - community.general
    - gaurav_gupta_gtm.ansible_kubeadm

- name: Install Necessary Software
  hosts: all
  vars_files:
    - group_vars/all.yml
  roles:
  -  role: runtime/{{ container_runtime }}_setup
  -  role: common
- name: Setup Master node
  hosts: master
  roles:
  -  role: master
  -  role: cni
- name: Setup worker  node
  hosts: worker
  roles:
  -  role: node

- hosts: master
  gather_facts: false
  tasks:
  - name: generate token on master
    shell: /usr/bin/kubeadm token generate
    register: token

  - name: generate token on master
    shell: /usr/bin/kubeadm token create "{{ token.stdout }}" --print-join-command
    register: join_cmd

  - name: set facts for the token
    set_fact:
       kube_token: "{{ join_cmd.stdout }}"

  - name: Copy Remote-To-Remote (from (first)master to other_master)
    synchronize:
        src: "{{ item }}"
        dest: "{{ item }}"
    delegate_to: master
    with_items:
    - /etc/kubernetes/pki/ca.crt
    - /etc/kubernetes/pki/ca.key
    - /etc/kubernetes/pki/sa.key
    - /etc/kubernetes/pki/sa.pub
    - /etc/kubernetes/pki/front-proxy-ca.crt
    - /etc/kubernetes/pki/front-proxy-ca.key
    - /etc/kubernetes/pki/etcd/ca.crt
    - /etc/kubernetes/pki/etcd/ca.key

- hosts: other_master
  gather_facts: false
  tasks:
  - name: copy token
    copy:
     content: "{{ hostvars['master']['kube_token'] }} --control-plane"
     dest: /root/join-kubernetes-cluster.sh
     mode: '0750'

  - name: join cluster
    shell: /root/join-kubernetes-cluster.sh
    register: joinlog

  - name: show log
    debug:
      msg: "{{ joinlog }}"

EOF

# ansible-playbook -i hosts.inv playbook.yml

# EOF
