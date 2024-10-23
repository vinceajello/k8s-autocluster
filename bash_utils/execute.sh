#!/bin/bashs

execute_script () {

    FILE_NAME=$1
    TARGET_IP=$2
    TARGET_SSH_PORT=$3
    REMOTE_USER=$4
    SSH_KEY_PATH=$5
    EXTRA_SCRIPT_ARGS="${@:6}"
    echo $EXTRA_SCRIPT_ARGS
    ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "LogLevel ERROR" -t $REMOTE_USER@$TARGET_IP -p $TARGET_SSH_PORT -i $SSH_KEY_PATH "sudo ./$FILE_NAME $EXTRA_SCRIPT_ARGS"
}