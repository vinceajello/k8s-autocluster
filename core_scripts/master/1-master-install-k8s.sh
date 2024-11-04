#!/bin/bash

POD_NETWORK_CIDR=$1
KUBERNETES_VERSION=$2

echo
echo "Updating the system"
sudo apt-get update

echo
echo "Upgrading the system"
sudo apt-get upgrade -y

# echo
# echo "Adding nodes to host file"
# echo "10.1.1.154 cmto-node-0" | sudo tee -a /etc/hosts
# echo "10.1.3.73 cmto-node-1" | sudo tee -a /etc/hosts
# echo "10.1.1.63 cmto-node-2" | sudo tee -a /etc/hosts

echo
echo "Disabling swap"
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo
echo "Adding modules"
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

echo
echo "Loading new modules"
sudo modprobe overlay
sudo modprobe br_netfilter

echo
echo "K8s network configuration"
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward = 1
EOF

echo
echo "Network configuration"
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf 

echo
echo "Reloading configurations"
sudo sysctl --system

echo
echo "Installing requirements"
sudo apt-get install -y curl ca-certificates gnupg

echo
echo "Adding docker repository"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo
echo "Updating the system"
sudo apt-get update

echo
echo "Installing containerd"
sudo apt-get install -y containerd.io

echo
echo "Configuring containerd"
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

echo
echo "Restarting containerd"
sudo systemctl restart containerd

echo
echo "Adding kubernetes repository"
sudo mkdir /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo
echo "Updating the system"
sudo apt-get update

echo
echo "Installing k8s components"
sudo apt-get install -y kubelet kubeadm kubectl

echo
echo "Stop updrades on k8s components"
sudo apt-mark hold kubelet kubeadm kubectl

echo
echo "Restarting kubelet"
sudo systemctl restart kubelet

echo
echo "Enabling kubelet"
sudo systemctl enable kubelet

echo
echo "Reloading systemd"
sudo sysctl --system

echo
echo "Pulling k8s confguration images"
sudo kubeadm config images pull

echo
echo "Init k8s"
sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR
