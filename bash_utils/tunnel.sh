#!/bin/bash

open_tunnel () {

    MASTER_NODE_IP=$1
    MASTER_NODE_USER=$2
    TARGET_NODE_IP=$3
    SSH_KEY_PATH=$4

    ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "LogLevel ERROR" -M -S /tmp/.node-tunnel -fNT -i $SSH_KEY_PATH -L 2222:$TARGET_NODE_IP:22 $MASTER_NODE_USER@$MASTER_NODE_IP
}

close_tunnel () {

    MASTER_NODE_IP=$1
    MASTER_NODE_USER=$2
    SSH_KEY_PATH=$3

    ssh -S /tmp/.node-tunnel -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "LogLevel ERROR" -O exit -i $SSH_KEY_PATH $MASTER_NODE_USER@$MASTER_NODE_IP
}

