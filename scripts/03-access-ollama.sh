#!/bin/bash

echo "=== Accessing Ollama API ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

export KUBECONFIG=./kubeconfig

echo -e "${BLUE}Starting port forwarding to Ollama API...${NC}"
echo "Ollama API will be available at: http://localhost:11434"
echo "Press Ctrl+C to stop"

# Start port forwarding
kubectl port-forward -n openwebui service/ollama-service 11434:11434
