#!/bin/bash

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
read -p "Remove known_hosts in /root/.ssh ? (y/n) " CONT
if [ "$CONT" = "y" ]; then
    rm /root/.ssh/known_hosts
fi
### /OPTIONAL REMOVE KNOWN_HOSTS
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
echo
read -p "Confirm VARS ? (y/n) " CONT
if [ "$CONT" = "n" ]; then
    exit 1
fi
### /CHECK VARS
###
###
echo
echo "Uploading scripts on master node ($MASTER_NODE_IP)..."
scp -o "StrictHostKeyChecking=no" -i $SSH_KEY 0-master-create-user.sh $REMOTE_USER@$MASTER_NODE_IP:/home/$REMOTE_USER/
scp -o "StrictHostKeyChecking=no" -i $SSH_KEY 1-master-install-k8s.sh $REMOTE_USER@$MASTER_NODE_IP:/home/$REMOTE_USER/
scp -o "StrictHostKeyChecking=no" -i $SSH_KEY 2-master-config-k8s.sh $REMOTE_USER@$MASTER_NODE_IP:/home/$REMOTE_USER/
scp -o "StrictHostKeyChecking=no" -i $SSH_KEY 3-master-get-install-link.sh $REMOTE_USER@$MASTER_NODE_IP:/home/$REMOTE_USER/
echo "Scripts uploading done"; echo
###
###
echo "Executing uploaded scripts on master node ($MASTER_NODE_IP)..."
ssh -o "StrictHostKeyChecking=no" -t $REMOTE_USER@$MASTER_NODE_IP -i $SSH_KEY ./0-create-user.sh
ssh -o "StrictHostKeyChecking=no" -t $REMOTE_USER@$MASTER_NODE_IP -i $SSH_KEY sudo ./1-master-install-k8s.sh $POD_NETWORK_CIDR $KUBERNETES_VERSION
ssh -o "StrictHostKeyChecking=no" -t $REMOTE_USER@$MASTER_NODE_IP -i $SSH_KEY sudo ./2-master-config-k8s.sh $MASTER_NODE_HOSTNAME $CALICO_VERSION $K9S_VERSION
ssh -o "StrictHostKeyChecking=no" -t $REMOTE_USER@$MASTER_NODE_IP -i $SSH_KEY sudo ./3-master-get-install-link.sh > 4-node-join-command.sh
sed -i -e "s/\r//g" 4-node-join-command.sh
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
    ssh -i $SSH_KEY -o "StrictHostKeyChecking=no" -M -S /tmp/.node-tunnel -fNT -L 2222:$NODE_IP:22 $REMOTE_USER@$MASTER_NODE_IP
    ###
    echo "  Uploading scripts on worker node using tunnel (localhost:2222)..."
    scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o "LogLevel ERROR" -i $SSH_KEY 4-node-install-k8s.sh $REMOTE_USER@localhost:/home/$REMOTE_USER/
    scp -P 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o "LogLevel ERROR" -i $SSH_KEY 4-node-join-command.sh $REMOTE_USER@localhost:/home/$REMOTE_USER/
    ###
    echo "Executing uploaded scripts on worker node using tunnel (localhost:2222)..."
    ssh -p 2222 -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o "LogLevel ERROR"  -t $REMOTE_USER@localhost -i $SSH_KEY sudo ./4-node-install-k8s.sh $KUBERNETES_VERSION
    ssh -p 2222 -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o "LogLevel ERROR"  -t $REMOTE_USER@localhost -i $SSH_KEY sudo ./4-node-join-command.sh
    ###
    echo "  Closing tunnel..."
    ssh -i $SSH_KEY -S /tmp/.node-tunnel -o StrictHostKeyChecking=no -o "LogLevel ERROR" -O exit $REMOTE_USER@$MASTER_NODE_IP; echo
    ###
    ###
    echo "Worker node at ($NODE_IP) joined"; echo
}
###
###
for key in "${!nodes[@]}"
do run_on_node ${nodes[$key]}
done
###
###
echo "done"