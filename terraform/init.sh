#!/bin/bash

CLUSTER="development-cluster"
IMAGE_NAME="clock:ci"

if kind get clusters | grep -q ${CLUSTER}; then
    read -p "Cluster ${CLUSTER} already exists. Do you want to delete and recreate it (if n just continue)? (y/n) " answer
    if [ "$answer" = "y" ]; then
        kind delete cluster --name ${CLUSTER} > /dev/null 2>&1
        kind create cluster --config ../helm/kind-config.yaml --name ${CLUSTER} --wait 60s
    fi
else
        kind delete cluster --name ${CLUSTER} > /dev/null 2>&1
        kind create cluster --config ../helm/kind-config.yaml --name ${CLUSTER} --wait 60s
fi

kind load docker-image ${IMAGE_NAME} --name ${CLUSTER}


terraform init
terraform plan
terraform apply