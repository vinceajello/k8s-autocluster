#!/bin/bash

echo "Installing portainer"

# create portainer data folder
sudo mkdir /mnt/portainer

kubectl apply -n portainer -f portainer.yaml

# Used to tunnel the service port to master node
# An additional tunnel from master node to local pc is needed to access the dashboard
# sudo kubectl -n portainer port-forward service/portainer 9000:9000
