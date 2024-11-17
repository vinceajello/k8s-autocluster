#!/bin/bash

# ./k8s-autocluster.sh

Little script big promises... 

k8s-autocluster is a bash script that helps to setup kubernetes clusters quickly
it leverage bash commands (mostly ssh and scp) to upload and execute a set of bash scripts 
on both master and worker nodes.

Executed scripts can be found in ./core_scripts/{master}||{node} directories of this repo.

## Requirements && Assumptions

k8s-autocluster is tested on Ubuntu 20.04 VPSs and Kubernetes 1.30 

- The same ssh key must be in place on each node
- Master node must be reachable over ssh, (the port number is configurable)
- Workers nodes must be reachable over ssh by master node.

## How to use

#### Configuration

SSH_KEY=./keys/id_rsa  
REMOTE_USER=ubuntu  
MASTER_NODE_IP=91.134.105.195  
MASTER_NODE_HOSTNAME=cmto-node-0
POD_NETWORK_CIDR=192.168.0.0/16  
MASTER_NODE_PRIVATE_IP=10.1.1.154
INGRESS_HTTP_PORT=30080
INGRESS_HTTPS_PORT=30443
CERTBOT_EMAIL=vince.ajello@gmail.com
KUBERNETES_VERSION=/v1.30/deb 
K9S_VERSION=v0.32.5/k9s_linux_amd64.deb  
CALICO_VERSION=v3.25.0  

nodes[0]="10.1.3.73"  
nodes[1]="10.1.1.63"  
nodes[2]="..."  

#### Run

(optionally) sudo chmod +x k8s-autocluster.sh
> sudo ./k8s-autocluster.sh

#### Author
pliz check the url ; P