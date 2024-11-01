#!/bin/bash

MASTER_NODE_IP=$1
REGISTRY_USER=$2

echo "Configuring k8s Master"

sudo mkdir /mnt/data
mkdir -p registry-auth
# mkdir -p certs

echo "Generating htpasswd file for user ($REGISTRY_USER)"
htpasswd -cB registry-auth/htpasswd $REGISTRY_USER

# openssl req -batch -newkey rsa:4096 -nodes -sha256 -keyout certs/registry.key -addext "subjectAltName = IP:$MASTER_NODE_IP" -x509 -days 3650 -out certs/registry.crt

sudo kubectl create namespace docker-registry

# sudo kubectl create secret tls registry-cert --cert=certs/registry.crt --key=certs/registry.key -n docker-registry

sudo kubectl create secret generic registry-auth --from-file=htpasswd=registry-auth/htpasswd -n docker-registry

sudo kubectl apply -f registry-pv.yaml

sudo kubectl apply -f registry-pvc.yaml

sudo kubectl apply -f registry-service.yaml

sudo kubectl apply -f registry-deploy.yaml

# Used to tunnel the service port to master node
# An additional tunnel from master node to local pc is needed to access the registry
# sudo kubectl -n docker-registry port-forward services/registry-service 5000:5000

# echo "uninstall"; sudo kubectl delete -f registry-deploy.yaml; sudo kubectl delete -f registry-pvc.yaml; sudo kubectl delete -f registry-service.yaml; sudo kubectl delete -f registry-pv.yaml; sudo rm -rf certs/; sudo rm -rf registry-auth/; sudo rm -rf /mnt/data/; sudo kubectl delete secret registry-auth registry-cert -n docker-registry;