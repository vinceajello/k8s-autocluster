#!/bin/bash

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

kubectl apply -f dashboard-user.yaml -n kubernetes-dashboard
kubectl apply -f dashboard-role.yaml -n kubernetes-dashboard
kubectl apply -f dashboard-secret.yaml -n kubernetes-dashboard

# Used to generate access token
# kubectl -n kubernetes-dashboard create token admin-user

# Used to tunnel the service port to master node
# An additional tunnel from master node to local pc is needed to access the dashboard
# kubectl -n kubernetes-dashboard port-forward service/kubernetes-dashboard 8443:443