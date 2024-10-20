#!/bin/bash

KUBERNETES_VERSION=$1

echo "Configuring k8s Worker"

echo
echo "Update the system"
apt update && apt upgrade -y
apt install socat -y
echo "OK"

echo
echo "Disable swap"
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo "OK"

echo
echo "Adding kernel modules"
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
echo "OK"

echo
echo "Reloading changes"
sysctl --system
echo "OK"

echo
echo "Adding docker repositoy"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmour --yes -o /etc/apt/trusted.gpg.d/docker.gpg
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
echo "OK"

echo
echo "Installing containerd runtime"
apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
apt update
apt install -y containerd.io
echo "OK"

echo
echo "Configuring containerd"
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
echo "OK"

echo
echo "Enabling containerd"
systemctl restart containerd
systemctl enable containerd
"OK"

echo
echo "Adding k8s repository"
apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:$KUBERNETES_VERSION/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:$KUBERNETES_VERSION/ /" | tee /etc/apt/sources.list.d/kubernetes.list
echo "OK"

echo
echo "Installing k8s "
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet
echo "OK"
