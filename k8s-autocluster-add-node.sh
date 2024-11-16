
source $(dirname $0)/bash_utils/upload.sh
source $(dirname $0)/bash_utils/execute.sh
source $(dirname $0)/bash_utils/tunnel.sh

MASTER_NODE_IP=91.134.105.195

NEW_NODE_IP=xxx
NEW_NODE_HOSTNAME=yyy

###
###
### RUN AS ROOT ROOT
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or sudo-ed"
  exit
fi

## GENERO SCRIPT DI CONFIGURAZIONE PER NODI PRECEDENTI
touch ./core_scripts/node/k8s-networking-configuration-add.sh
> ./core_scripts/node/k8s-networking-configuration-add.sh
echo "echo "\"${NEW_NODE_IP} ${NEW_NODE_HOSTNAME}\"" | sudo tee -a /etc/hosts" | tee -a ./core_scripts/node/k8s-networking-configuration-add.sh

## CARICO SCRIPT NECESSARIO
upload_file node k8s-autocluster-get-master-info.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 
upload_file node k8s-autocluster-get-nodes-info.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 

## OTTENGO INFO SU NODI PRECEDENTI
MASTER_NODE_INFO=$(execute_script ./k8s-autocluster-get-master-info.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa)
WORKER_NODES_INFO=()
WORKER_NODES_INFO_RAW=$(execute_script ./k8s-autocluster-get-nodes-info.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa)
for i in $WORKER_NODES_INFO_RAW; do WORKER_NODES_INFO+=($i) ; done

## GENERO SCRIPT DI CONFIGURAZIONE PER NUOVO NODO
touch ./core_scripts/node/k8s-networking-configuration-new.sh
> ./core_scripts/node/k8s-networking-configuration-new.sh
echo "echo "\"${MASTER_NODE_INFO}\"" | sudo tee -a /etc/hosts" | tee -a ./core_scripts/node/k8s-networking-configuration-new.sh
for ((i = 0; i < ${#WORKER_NODES_INFO[@]}; i++))
do
  SPLIT=(${WORKER_NODES_INFO[$i]//:/ })
  NODE_IP=${SPLIT[0]}
  HOSTNAME=${SPLIT[1]}
  echo "echo "\"${NODE_IP} ${HOSTNAME}\"" | sudo tee -a /etc/hosts" | tee -a ./core_scripts/node/k8s-networking-configuration-new.sh
done
echo "echo "\"${NEW_NODE_IP} ${NEW_NODE_HOSTNAME}\"" | sudo tee -a /etc/hosts" | tee -a ./core_scripts/node/k8s-networking-configuration-new.sh

## AGGIUNGO IL NUOVO NODO AI NODI PRECEDENTI
upload_file node k8s-networking-configuration-add.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa 
# execute_script ./k8s-networking-configuration-add.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
for ((i = 0; i < ${#WORKER_NODES_INFO[@]}; i++))
do
  SPLIT=(${WORKER_NODES_INFO[$i]//:/ })
  NODE_IP=${SPLIT[0]}
  open_tunnel $MASTER_NODE_IP ubuntu $NODE_IP ./keys/id_rsa 
  upload_file node k8s-networking-configuration-add.sh localhost 2222 ubuntu ./keys/id_rsa 
  # execute_script ./k8s-networking-configuration-add.sh localhost 2222 ubuntu ./keys/id_rsa
  close_tunnel $MASTER_NODE_IP ubuntu ./keys/id_rsa
done

## OTTENGO LO SCRIPT DI JOIN DAL MASTER
upload_file master 3-master-get-install-link.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa
execute_script ./3-master-get-install-link.sh $MASTER_NODE_IP 22 ubuntu ./keys/id_rsa > ./core_scripts/node/4-node-join-command.sh
sed -i -e "s/\r//g" ./core_scripts/node/4-node-join-command.sh

# open_tunnel $MASTER_NODE_IP ubuntu $NEW_NODE_IP ./keys/id_rsa 

## CARICO GLI SCRIPT SUL NUOVO NODO
# upload_file node k8s-networking-configuration-new.sh localhost 2222 ubuntu ./keys/id_rsa 
# upload_file node 4-node-install-k8s.sh localhost 2222 ubuntu ./keys/id_rsa 
# upload_file node 4-node-join-command.sh localhost 2222 ubuntu ./keys/id_rsa 

## ESEGUO GLI SCRIPT DI INSTALLAZIONE SUL NUOVO NODO
# execute_script ./k8s-networking-configuration-new.sh localhost 2222 ubuntu ./keys/id_rsa
# execute_script ./4-node-install-k8s.sh localhost 2222 ubuntu ./keys/id_rsa
# execute_script ./4-node-join-command.sh localhost 2222 ubuntu ./keys/id_rsa

# close_tunnel $MASTER_NODE_IP ubuntu ./keys/id_rsa
