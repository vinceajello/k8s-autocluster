#!/bin/bash

MASTER_NODE_HOSTNAME=$1
CALICO_VERSION=$2
K9S_VERSION=$3

echo "Configuring k8s Master"

echo
echo "Adding k8s to PATHs"
mkdir -p $HOME/.kube
yes | cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
echo "OK"

# install calico
sudo kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/calico.yaml

# install k9s
wget https://github.com/derailed/k9s/releases/download/$K9S_VERSION
sudo chown _apt /var/lib/update-notifier/package-data-downloads/partial/
sudo chown -Rv _apt:root /var/cache/apt/archives/partial/
sudo chmod -Rv 700 /var/cache/apt/archives/partial/
apt install ./k9s_linux_amd64.deb
rm ./k9s_linux_amd64.deb

# install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm ./get_helm.sh

# remove the taint from master node
kubectl taint nodes $MASTER_NODE_HOSTNAME node-role.kubernetes.io/control-plane:NoSchedule-

# adding useful aliases
echo "alias kca='sudo kubectl get pods -o wide -A; sudo kubectl get services -A; sudo kubectl get nodes'" >> .bashrc
echo "alias kc='sudo kubectl'" >> .bashrc
