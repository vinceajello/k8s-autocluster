#!/bin/bash

MASTER_NODE_IP=$1
REGISTRY_USER=$2

echo "Configuring k8s Master"

mkdir -p certs

mkdir -p registry-auth

sudo mkdir /mnt/data

echo "Generating htpasswd file for user ($REGISTRY_USER)"
htpasswd -c registry-auth/htpasswd $REGISTRY_USER

openssl req -batch -newkey rsa:4096 -nodes -sha256 -keyout certs/registry.key -addext "subjectAltName = IP:$MASTER_NODE_IP" -x509 -days 3650 -out certs/registry.crt

sudo kubectl create namespace docker-registry

sudo kubectl create secret tls registry-cert --cert=certs/registry.crt --key=certs/registry.key -n docker-registry

sudo kubectl create secret generic registry-auth --from-file=htpasswd=registry-auth/htpasswd -n docker-registry

sudo kubectl apply -f registry-pv.yaml

sudo kubectl apply -f registry-pvc.yaml

sudo kubectl apply -f registry-service.yaml

sudo kubectl apply -f registry-deploy.yaml

# Used to tunnel the service port to master node
# An additional tunnel from master node to local pc is needed to access the registry
# sudo kubectl -n docker-registry port-forward services/registry-service 5000:5000
