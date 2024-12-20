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
### VARS
SSH_KEY=./keys/id_rsa
REMOTE_USER=ubuntu
KUBERNETES_VERSION=1.30
MASTER_NODE_IP=91.134.105.195
MASTER_NODE_HOSTNAME=cmto-node-0
MASTER_NODE_PRIVATE_IP=10.1.1.154
POD_NETWORK_CIDR=192.168.0.0/16
INGRESS_HTTP_PORT=30080
INGRESS_HTTPS_PORT=30443
CERTBOT_EMAIL=vince.ajello@gmail.com
K9S_VERSION=v0.32.5/k9s_linux_amd64.deb
CALICO_VERSION=v3.28.1
###
###
DO_INSTALL_DASHBOARD=$_DO_INSTALL_DASHBOARD
DO_INSTALL_PORTAINER=$_DO_INSTALL_PORTAINER
### /VARS
###
### 
### NODES
declare -A nodes
nodes[0]="10.1.3.73:cmto-node-1"
# nodes[1]="10.1.1.63:cmto-node-2"
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
echo "MASTER_NODE_PRIVATE_IP:$MASTER_NODE_PRIVATE_IP"
echo "MASTER_NODE_HOSTNAME:$MASTER_NODE_HOSTNAME"
echo "-------------------------"
echo "INGRESS_HTTP_PORT:$INGRESS_HTTP_PORT"
echo "INGRESS_HTTPS_PORT:$INGRESS_HTTPS_PORT"
echo "CERTBOT_EMAIL:$CERTBOT_EMAIL"
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
echo "Generating networking configuration script"
###
###
build_network_conf_command () {
    SPLIT=(${1//:/ })
    NODE_IP=${SPLIT[0]}
    HOSTNAME=${SPLIT[1]}
    echo "echo "\"${NODE_IP} ${HOSTNAME}\"" | sudo tee -a /etc/hosts" | tee -a ./core_scripts/master/k8s-networking-configuration.sh
}
###
###
touch ./core_scripts/master/k8s-networking-configuration.sh
> ./core_scripts/master/k8s-networking-configuration.sh
###
###
echo "echo "\"${MASTER_NODE_PRIVATE_IP} ${MASTER_NODE_HOSTNAME}\"" | sudo tee -a /etc/hosts" | tee -a ./core_scripts/master/k8s-networking-configuration.sh
for key in "${!nodes[@]}"
do build_network_conf_command ${nodes[$key]}
done
cp ./core_scripts/master/k8s-networking-configuration.sh ./core_scripts/node/k8s-networking-configuration.sh
echo "Configuration script generated"; echo
###
###
###
echo
echo "Uploading scripts on master node ($MASTER_NODE_IP)..."
upload_file master k8s-networking-configuration.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 
upload_file master 0-master-create-user.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 
upload_file master 1-master-install-k8s.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 
upload_file master 2-master-config-k8s.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 
upload_file master 3-master-get-install-link.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
upload_file master/ingress master-install-nginx-ingress.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
upload_file master/ingress nginx-ingress-controller.yaml $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
upload_file master/cert-manager master-install-cert-manager.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
upload_file master/cert-manager cert-manager-cluster-issuer.yaml $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
echo "Scripts uploading done"; echo
###
###
echo "Executing uploaded scripts on master node ($MASTER_NODE_IP)..."
execute_script ./k8s-networking-configuration.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
execute_script ./0-master-create-user.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
execute_script ./1-master-install-k8s.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa $POD_NETWORK_CIDR $KUBERNETES_VERSION
execute_script ./2-master-config-k8s.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa $MASTER_NODE_HOSTNAME $K9S_VERSION $CALICO_VERSION $POD_NETWORK_CIDR
execute_script ./master-install-nginx-ingress.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa $INGRESS_HTTP_PORT $INGRESS_HTTPS_PORT
execute_script ./master-install-cert-manager.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa $CERTBOT_EMAIL 
execute_script ./3-master-get-install-link.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa > ./core_scripts/node/4-node-join-command.sh
sed -i -e "s/\r//g" ./core_scripts/node/4-node-join-command.sh
echo "Scripts execution done"; echo
###
###
###
run_on_node () {

    SPLIT=(${1//:/ })
    NODE_IP=${SPLIT[0]}
    HOSTNAME=${SPLIT[1]}
    ###
    ###
    echo "Configuring worker node at ($NODE_IP)..."; echo
    ###
    ###
    echo "  Creating tunnel to worker node ($NODE_IP)..."
    open_tunnel $MASTER_NODE_IP $REMOTE_USER $NODE_IP $SSH_KEY
    ###
    echo "  Uploading scripts on worker node using tunnel (localhost:2222)..."
    upload_file node k8s-networking-configuration.sh localhost 2222 ubuntu ./keys/id_rsa 
    upload_file node 4-node-install-k8s.sh localhost 2222 ubuntu ./keys/id_rsa 
    upload_file node 4-node-join-command.sh localhost 2222 ubuntu ./keys/id_rsa 
    ###
    echo "Executing uploaded scripts on worker node using tunnel (localhost:2222)..."
    execute_script ./k8s-networking-configuration.sh localhost 2222 ubuntu ./keys/id_rsa
    execute_script ./4-node-install-k8s.sh localhost 2222 ubuntu ./keys/id_rsa $KUBERNETES_VERSION
    execute_script "sudo ./4-node-join-command.sh" localhost 2222 ubuntu ./keys/id_rsa
    ###
    echo "  Closing tunnel..."
    close_tunnel $MASTER_NODE_IP $REMOTE_USER $SSH_KEY
    ###
    ###
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
    upload_file master/dashboard dashboard-user.yaml $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 
    upload_file master/dashboard dashboard-role.yaml $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 
    upload_file master/dashboard dashboard-secret.yaml $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
    upload_file master/dashboard master-install-dashboard.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
    execute_script ./master-install-dashboard.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
    echo "Dashboard installed on master node"; echo
fi
###
###
### INSTALL PORTAINER
###
###
if [ "$DO_INSTALL_PORTAINER" = 1 ]; then
    echo "Installing portainer on master node..."
    upload_file master/portainer portainer.yaml $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 
    upload_file master/portainer master-install-portainer.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
    execute_script ./master-install-portainer.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
    echo "Portainer installed on master node"; echo
fi
###
###
### INSTALL NGINX PRIVATE
###
###
if [ "$DO_INSTALL_DASHBOARD" = 1 ] || [ "$DO_INSTALL_PORTAINER" = 1 ]; then
    echo "Installing nginx private proxy on master node..."
    upload_file master/nginx-private nginx-private.yaml $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 
    upload_file master/nginx-private master-install-nginx-private.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 
    execute_script ./master-install-nginx-private.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
fi
###
###
### CLEANUP
###
###
echo "Cleanup..."
rm ./core_scripts/node/4-node-join-command.sh 2> /dev/null
rm ./core_scripts/node/k8s-networking-configuration.sh 2> /dev/null
rm ./core_scripts/master/k8s-networking-configuration.sh 2> /dev/null
###
###
echo "done"
