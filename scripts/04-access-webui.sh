#!/bin/bash

echo "=== Accessing Open WebUI ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

export KUBECONFIG=./kubeconfig

# Check if we have a public IP
PUBLIC_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "null" ]; then
    echo -e "${GREEN}Public IP available!${NC}"
    echo "Open WebUI: http://$PUBLIC_IP"
    echo ""
    echo "You can access it directly from any browser"
else
    echo -e "${YELLOW}No public IP available, using port forwarding...${NC}"
    echo "Open WebUI will be available at: http://localhost:8080"
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Start port forwarding
    kubectl port-forward -n openwebui service/open-webui-service 8080:80
fi
