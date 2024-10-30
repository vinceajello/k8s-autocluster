#!/bin/bash

source $(dirname $0)/bash_utils/upload.sh
source $(dirname $0)/bash_utils/execute.sh
source $(dirname $0)/bash_utils/tunnel.sh

echo
echo "::: K8s Autocluster ::: 0.1 :::"

echo
###
###
### RUN AS ROOT ROOT
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or sudo-ed"
  exit
fi
### /RUN AS ROOT ROOT
###
###
### OPTIONAL REMOVE KNOWN_HOSTS
read -p "Remove known_hosts in /root/.ssh ? (y/n) default:n " CONT
if [ "$CONT" = "y" ]; then
    rm /root/.ssh/known_hosts
fi
### /OPTIONAL REMOVE KNOWN_HOSTS
###
###
### ASK FOR DASHBOARD
_DO_INSTALL_DASHBOARD=1
read -p "Install k8s dashboard ? (y/n) default:y " X
if [ "$X" = "n" ]; then
    _DO_INSTALL_DASHBOARD=0
fi
### /ASK FOR DASHBOARD
###
###
### ASK FOR PORTAINER
_DO_INSTALL_PORTAINER=1
read -p "Install portainer ? (y/n) default:y " X
if [ "$X" = "n" ]; then
    _DO_INSTALL_PORTAINER=0
fi
### /ASK FOR PORTAINER
###
###
### ASK FOR DOCKER REGISTRY
_DO_INSTALL_DOCKER_REGISTRY=1
read -p "Install docker registry ? (y/n) default:y " X
if [ "$X" = "n" ]; then
    _DO_INSTALL_DOCKER_REGISTRY=0
fi
### /ASK FOR DOCKER REGISTRY
###
###
### VARS
SSH_KEY=./keys/id_rsa
REMOTE_USER=ubuntu
MASTER_NODE_IP=91.134.105.195
POD_NETWORK_CIDR=192.168.0.0/16
KUBERNETES_VERSION=/v1.30/deb
K9S_VERSION=v0.32.5/k9s_linux_amd64.deb
CALICO_VERSION=v3.25.0
MASTER_NODE_HOSTNAME=cmto-node-0
DO_INSTALL_DASHBOARD=$_DO_INSTALL_DASHBOARD
DO_INSTALL_PORTAINER=$_DO_INSTALL_PORTAINER
DO_INSTALL_DOCKER_REGISTRY=$_DO_INSTALL_DOCKER_REGISTRY
DOCKER_REGISTRY_USER="registry-admin"
### /VARS
###
### 
### NODES
declare -A nodes
nodes[0]="10.1.3.73"
nodes[1]="10.1.1.63"
### /NODES
###
###
### CHECK VARS
echo
echo "SSH_KEY:$SSH_KEY"
echo "REMOTE_USER:$REMOTE_USER"
echo "-------------------------"
echo "POD_NETWORK_CIDR:$POD_NETWORK_CIDR"
echo "MASTER_NODE_IP:$MASTER_NODE_IP"
echo "MASTER_NODE_HOSTNAME:$MASTER_NODE_HOSTNAME"
echo "-------------------------"
echo "WORKER NODES:"
for key in "${!nodes[@]}"
do echo ${nodes[$key]}
done
echo "-------------------------"
echo "KUBERNETES_VERSION:$KUBERNETES_VERSION"
echo "K9S_VERSION:$K9S_VERSION"
echo "CALICO_VERSION:$CALICO_VERSION"
echo "-------------------------"
echo "INSTALL_DASHBOARD:$DO_INSTALL_DASHBOARD"
echo "INSTALL_PORTAINER:$DO_INSTALL_PORTAINER"
echo "INSTALL_DOCKER_REGISTRY:$DO_INSTALL_DOCKER_REGISTRY"
echo "DOCKER_REGISTRY_USER:$DOCKER_REGISTRY_USER"
echo
###
###
read -p "Confirm VARS ? (y/n) default:y " X
if [ "$X" = "n" ]; then
    exit 1
fi
### /CHECK VARS
###
###
echo
echo "Uploading scripts on master node ($MASTER_NODE_IP)..."
upload_file master 0-master-create-user.sh 91.134.105.195 22 ubuntu ./keys/id_rsa 
upload_file master 1-master-install-k8s.sh 91.134.105.195 22 ubuntu ./keys/id_rsa 
upload_file master 2-master-config-k8s.sh 91.134.105.195 22 ubuntu ./keys/id_rsa 
upload_file master 3-master-get-install-link.sh 91.134.105.195 22 ubuntu ./keys/id_rsa 
echo "Scripts uploading done"; echo
###
###
echo "Executing uploaded scripts on master node ($MASTER_NODE_IP)..."
execute_script 0-master-create-user.sh 91.134.105.195 22 ubuntu ./keys/id_rsa
execute_script 1-master-install-k8s.sh 91.134.105.195 22 ubuntu ./keys/id_rsa $POD_NETWORK_CIDR $KUBERNETES_VERSION
execute_script 2-master-config-k8s.sh 91.134.105.195 22 ubuntu ./keys/id_rsa $MASTER_NODE_HOSTNAME $CALICO_VERSION $K9S_VERSION
execute_script 3-master-get-install-link.sh 91.134.105.195 22 ubuntu ./keys/id_rsa > ./core_scripts/node/4-node-join-command.sh
#sed -i -e "s/\r//g" ./core_scripts/node/4-node-join-command.sh
###
###
echo "Scripts execution done"; echo
###
###
run_on_node () {

    NODE_IP=$1
    ###
    ###
    echo "Configuring worker node at ($NODE_IP)..."; echo
    ###
    ###
    echo "  Creating tunnel to worker node ($NODE_IP)..."
    open_tunnel $MASTER_NODE_IP $REMOTE_USER $NODE_IP $SSH_KEY
    ###
    echo "  Uploading scripts on worker node using tunnel (localhost:2222)..."
    upload_file node 4-node-install-k8s.sh localhost 2222 ubuntu ./keys/id_rsa 
    upload_file node 4-node-join-command.sh localhost 2222 ubuntu ./keys/id_rsa 
    ###
    echo "Executing uploaded scripts on worker node using tunnel (localhost:2222)..."
    execute_script 4-node-install-k8s.sh localhost 2222 ubuntu ./keys/id_rsa $KUBERNETES_VERSION
    execute_script 4-node-join-command.sh localhost 2222 ubuntu ./keys/id_rsa
    ###
    echo "  Closing tunnel..."
    close_tunnel $MASTER_NODE_IP $REMOTE_USER $SSH_KEY
    ###
    ###
    echo "Worker node at ($NODE_IP) joined"; echo
}
###
### RUN 'run_on_node' ON EACH NODE DEFINED
###
for key in "${!nodes[@]}"
do run_on_node ${nodes[$key]}
done
###
###
### INSTALL K8S DASHBOARD
###
###
if [ "$DO_INSTALL_DASHBOARD" = 1 ]; then
    echo "Installing k8s dashboard on master node..."
    upload_file master/dashboard dashboard-user.yaml 91.134.105.195 22 ubuntu ./keys/id_rsa 
    upload_file master/dashboard dashboard-role.yaml 91.134.105.195 22 ubuntu ./keys/id_rsa 
    upload_file master/dashboard dashboard-secret.yaml 91.134.105.195 22 ubuntu ./keys/id_rsa
    upload_file master/dashboard 5-master-install-dashboard.sh 91.134.105.195 22 ubuntu ./keys/id_rsa
    execute_script 5-master-install-dashboard.sh 91.134.105.195 22 ubuntu ./keys/id_rsa
    echo "Dashboard installed on master node"; echo
fi
###
###
### INSTALL PORTAINER
###
###
if [ "$DO_INSTALL_PORTAINER" = 1 ]; then
    echo "Installing portainer on master node..."
    upload_file master/portainer portainer.yaml 91.134.105.195 22 ubuntu ./keys/id_rsa 
    upload_file master/portainer 6-master-install-portainer.sh 91.134.105.195 22 ubuntu ./keys/id_rsa
    execute_script 6-master-install-portainer.sh 91.134.105.195 22 ubuntu ./keys/id_rsa
    echo "Portainer installed on master node"; echo
fi
###
###
### INSTALL DOCKER REGISTRY
###
###
if [ "$DO_INSTALL_DOCKER_REGISTRY" = 1 ]; then
    echo "Installing docekr registry on master node..."
    upload_file master/docker-registry registry-pv.yaml 91.134.105.195 22 ubuntu ./keys/id_rsa 
    upload_file master/docker-registry registry-pvc.yaml 91.134.105.195 22 ubuntu ./keys/id_rsa 
    upload_file master/docker-registry registry-deploy.yaml 91.134.105.195 22 ubuntu ./keys/id_rsa 
    upload_file master/docker-registry registry-service.yaml 91.134.105.195 22 ubuntu ./keys/id_rsa 
    upload_file master/docker-registry 7-master-install-docker-registry.sh 91.134.105.195 22 ubuntu ./keys/id_rsa 
    execute_script 7-master-install-docker-registry.sh 91.134.105.195 22 ubuntu ./keys/id_rsa $MASTER_NODE_IP $DOCKER_REGISTRY_USER
    echo "Docker registry installed on master node"; echo
fi
###
###
echo "done"
