#!/bin/bash
set -e

echo "=== Complete Open WebUI Deployment ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Make scripts executable
chmod +x scripts/*.sh

echo -e "${YELLOW}Step 1: Deploying Azure Infrastructure...${NC}"
./scripts/01-deploy-infrastructure.sh

if [ $? -eq 0 ]; then
    echo -e "${YELLOW}Step 2: Deploying Applications...${NC}"
    ./scripts/02-deploy-applications.sh
    
    echo -e "${GREEN}=== Deployment Completed Successfully! ===${NC}"
    echo ""
    echo -e "${YELLOW}Access Methods:${NC}"
    echo "1. Open WebUI: ./scripts/04-access-webui.sh"
    echo "2. Ollama API: ./scripts/03-access-ollama.sh"
    echo "3. Troubleshoot: ./scripts/05-troubleshoot.sh"
    echo ""
    echo -e "${GREEN}Your Open WebUI with Ollama and Llama2 is ready!${NC}"
else
    echo -e "${RED}=== Deployment Failed ===${NC}"
    echo "Check the error above and run ./scripts/05-troubleshoot.sh for diagnostics"
    exit 1
fi
