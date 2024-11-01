#!/bin/bash

CALICO_VERSION=$1

# install calico
sudo kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/calico.yaml
