#!/bin/bash

NODES_IPS=()
NODES_HOSTNAMES=()
NODES_INFOS=()
NODES_IPS_OUTPUT=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
NODES_HOSTNAMES_OUTPUT=$(kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].status.addresses[?(@.type=="Hostname")].address}')
for i in $NODES_IPS_OUTPUT; do NODES_IPS+=($i) ; done
for i in $NODES_HOSTNAMES_OUTPUT; do NODES_HOSTNAMES+=($i) ; done
for ((i = 0; i < ${#NODES_IPS[@]}; i++))
do
    NODES_INFOS+=(${NODES_IPS[$i]}:${NODES_HOSTNAMES[$i]})
done
echo -n "${NODES_INFOS[@]}"