#!/bin/bash

CLUSTER="development-cluster"
NAMESPACE="clock"
RELEASE_NAME="my-clock-release"
IMAGE_NAME="clock:ci"
HELM_PATH="./clock-local"

# 1. Create cluster (adding -q to keep it quiet if you prefer)
# Recreate cluster if exist, ask if Yes, delete and create, if No, exit
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


# Install Traefik Ingress Controller
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm upgrade --install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443 \
  --set deployment.kind=DaemonSet \
  --set "tolerations[0].key=node-role.kubernetes.io/control-plane" \
  --set "tolerations[0].effect=NoSchedule" \
  --set-string "nodeSelector.ingress-ready=true"

kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.3/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
# 2. Load the image
# Make sure you've run 'docker build -t clock:ci .' before this!
kind load docker-image ${IMAGE_NAME} --name ${CLUSTER}

# 3. Prepare and Install Helm Chart
cd ${HELM_PATH}
helm dependency build
# The Traefik CRDs are required for the Ingress to work properly. We can apply them directly from the Traefik GitHub repository.
# Using upgrade --install is safer if you run the script multiple times
helm upgrade --install ${RELEASE_NAME} .  --namespace ${NAMESPACE} --create-namespace
cd - > /dev/null
#sleep 15 # Give it a moment to stabilize

echo "Waiting for pod to be scheduled and running..."
# This will wait for the pod to actually exist and pass its readiness check
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=${RELEASE_NAME} --timeout=120s

# If the wait fails, let's see why before trying to port-forward
if [ $? -ne 0 ]; then
   echo "Pod failed to start. Dumping logs/events:"
   kubectl get pods
   kubectl describe pods -l app.kubernetes.io/instance=${RELEASE_NAME}
   #sleep 15 # Give it a moment to stabilize
fi
#kubectl port-forward svc/${RELEASE_NAME} 8080:80