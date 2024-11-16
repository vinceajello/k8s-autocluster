#!/bin/bash

CERTBOT_EMAIL=$1

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.12.0 --set installCRDs=true

sed -i "s/email: example@email.com/email: $CERTBOT_EMAIL/" cert-manager-cluster-issuer.yaml

kubectl apply -f cert-manager-cluster-issuer.yaml

