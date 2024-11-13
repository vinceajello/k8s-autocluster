#!/bin/bash 

HTTP_NODEPORT=$1
HTTPS_NODEPORT=$2

echo
echo "Installing public nginx ingress"

sed -i "s/nodePort: 30080/nodePort: $HTTP_NODEPORT/" nginx-ingress-controller.yaml
sed -i "s/nodePort: 30443/nodePort: $HTTPS_NODEPORT/" nginx-ingress-controller.yaml

kubectl apply -f nginx-ingress-controller.yaml