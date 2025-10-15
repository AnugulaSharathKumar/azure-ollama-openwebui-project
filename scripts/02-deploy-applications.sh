#!/bin/bash
set -e

echo "=== Deploying Applications to AKS ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

export KUBECONFIG=./kubeconfig

print_status "Step 1: Creating namespace..."
kubectl apply -f kubernetes/namespace.yaml

print_status "Step 2: Creating storage class..."
kubectl apply -f kubernetes/storage-class.yaml

print_status "Step 3: Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

print_status "Step 4: Waiting for ingress controller..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

print_status "Step 5: Deploying Ollama..."
kubectl apply -f kubernetes/ollama-deployment.yaml

print_status "Step 6: Waiting for Ollama to be ready..."
kubectl wait --namespace openwebui \
  --for=condition=ready pod \
  --selector=app=ollama \
  --timeout=600s

print_status "Step 7: Deploying Open WebUI..."
kubectl apply -f kubernetes/openwebui-deployment.yaml

print_status "Step 8: Waiting for Open WebUI to be ready..."
kubectl wait --namespace openwebui \
  --for=condition=ready pod \
  --selector=app=open-webui \
  --timeout=300s

print_status "Step 9: Loading Llama2 model (this will take 10-15 minutes)..."
OLLAMA_POD=$(kubectl get pods -n openwebui -l app=ollama -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n openwebui $OLLAMA_POD -- ollama pull llama2:7b

print_success "Applications deployed successfully!"
echo ""
kubectl get all -n openwebui
