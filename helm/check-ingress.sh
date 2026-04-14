# 1. Check Traefik is actually running
kubectl get pods -n traefik
kubectl get svc -n traefik

# 2. Check the ingress was created and has an address
kubectl get ingress

# 3. Check kind cluster has the port mappings
kubectl get node -o yaml | grep -A5 "extraPortMappings\|hostPort"