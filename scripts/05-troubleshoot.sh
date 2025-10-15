#!/bin/bash

echo "=== Troubleshooting Deployment ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

export KUBECONFIG=./kubeconfig

echo -e "${BLUE}1. Checking cluster status...${NC}"
kubectl cluster-info
kubectl get nodes

echo -e "${BLUE}2. Checking all pods...${NC}"
kubectl get pods --all-namespaces

echo -e "${BLUE}3. Checking openwebui namespace...${NC}"
kubectl get all -n openwebui

echo -e "${BLUE}4. Checking pod logs...${NC}"
OLLAMA_POD=$(kubectl get pods -n openwebui -l app=ollama -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "NOT_FOUND")
OPENWEBUI_POD=$(kubectl get pods -n openwebui -l app=open-webui -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "NOT_FOUND")

if [ "$OLLAMA_POD" != "NOT_FOUND" ]; then
    echo -e "${BLUE}Ollama logs:${NC}"
    kubectl logs -n openwebui $OLLAMA_POD --tail=20
fi

if [ "$OPENWEBUI_POD" != "NOT_FOUND" ]; then
    echo -e "${BLUE}Open WebUI logs:${NC}"
    kubectl logs -n openwebui $OPENWEBUI_POD --tail=20
fi

echo -e "${BLUE}5. Checking events...${NC}"
kubectl get events -n openwebui --sort-by='.lastTimestamp' | tail -10

echo -e "${BLUE}6. Checking services...${NC}"
kubectl get services -n openwebui

echo -e "${BLUE}7. Checking storage...${NC}"
kubectl get pvc -n openwebui

echo -e "${GREEN}Troubleshooting complete!${NC}"
