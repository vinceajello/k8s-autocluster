#!/bin/bash

SCRIPT_PATH=./core_scripts

upload_file () {

    KIND=$1
    FILE_NAME=$2
    TARGET_IP=$3
    TARGET_SSH_PORT=$4
    REMOTE_USER=$5
    SSH_KEY_PATH=$6
    scp -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "LogLevel ERROR" -i "$SSH_KEY_PATH" -P $TARGET_SSH_PORT "$SCRIPT_PATH/$KIND/$FILE_NAME" $REMOTE_USER@$TARGET_IP:/home/$REMOTE_USER/
}