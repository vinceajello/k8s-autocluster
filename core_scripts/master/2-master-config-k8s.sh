#!/bin/bash

MASTER_NODE_HOSTNAME=$1
K9S_VERSION=$2
CALICO_VERSION=$3
CIDR=$4

echo "Configuring k8s Master"

echo
echo "Adding k8s to PATHs"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "OK"

echo
echo "Installing k9s control panel"
wget https://github.com/derailed/k9s/releases/download/$K9S_VERSION
sudo apt install ./k9s_linux_amd64.deb
rm ./k9s_linux_amd64.deb

echo
echo "Installing helm packet manager"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm ./get_helm.sh

echo
echo "Removing taint from control-plane node"
kubectl taint nodes $MASTER_NODE_HOSTNAME node-role.kubernetes.io/control-plane:NoSchedule-

echo
echo "Labelling control-plane node as master"
kubectl label nodes $MASTER_NODE_HOSTNAME nodeRole=master

echo
echo "Installing Calico"
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/custom-resources.yaml -O
sed -i "s|192\.168\.0\.0/16|${CIDR}|g" custom-resources.yaml
sed -i 's/VXLANCrossSubnet/VXLAN/g' custom-resources.yaml
kubectl create -f custom-resources.yaml

echo
echo "Adding useful aliases"
echo "alias kca='kubectl get deployments -A; kubectl get pods -o wide -A; kubectl get services -A; kubectl get nodes'" >> .bashrc
