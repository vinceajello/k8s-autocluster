#!/bin/bash

MASTER_IP=$(kubectl get nodes --selector='node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
MASTER_HOSTNAME=$(kubectl get nodes --selector='node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].status.addresses[?(@.type=="Hostname")].address}')
echo -n $MASTER_IP $MASTER_HOSTNAME
