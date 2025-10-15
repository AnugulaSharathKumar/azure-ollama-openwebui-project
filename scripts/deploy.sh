#!/bin/bash

set -e

echo "Starting Open WebUI deployment on Azure AKS..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    print_status "All prerequisites are satisfied."
}

# Azure login
azure_login() {
    print_status "Checking Azure login..."
    az account show > /dev/null 2>&1 || {
        print_warning "You are not logged into Azure. Please log in..."
        az login
    }
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_status "Deploying AKS cluster with Terraform..."
    
    cd terraform
    terraform init
    terraform plan -out=plan.out
    terraform apply -auto-approve plan.out
    
    # Get kubeconfig
    terraform output -raw kube_config > ../kubeconfig
    export KUBECONFIG=../kubeconfig
    
    cd ..
}

# Setup Kubernetes resources
setup_kubernetes() {
    print_status "Setting up Kubernetes resources..."
    
    # Create namespace
    kubectl apply -f kubernetes/namespace.yaml
    
    # Install NGINX Ingress Controller
    print_status "Installing NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
    
    # Wait for ingress controller to be ready
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=120s
    
    # Deploy Ollama
    print_status "Deploying Ollama..."
    kubectl apply -f kubernetes/ollama-deployment.yaml
    
    # Wait for Ollama to be ready
    print_status "Waiting for Ollama to be ready..."
    kubectl wait --namespace openwebui \
      --for=condition=ready pod \
      --selector=app=ollama \
      --timeout=300s
    
    # Deploy Open WebUI
    print_status "Deploying Open WebUI..."
    kubectl apply -f kubernetes/openwebui-deployment.yaml
    
    # Deploy ingress (optional - comment out if no domain configured)
    # kubectl apply -f kubernetes/ingress.yaml
}

# Load Llama2 model into Ollama
load_llama_model() {
    print_status "Loading Llama2 model into Ollama..."
    
    # Get Ollama pod name
    OLLAMA_POD=$(kubectl get pods -n openwebui -l app=ollama -o jsonpath='{.items[0].metadata.name}')
    
    # Pull and run Llama2 model
    kubectl exec -n openwebui $OLLAMA_POD -- ollama pull llama2:7b
    
    print_status "Llama2 model loaded successfully."
}

# Get access information
get_access_info() {
    print_status "Getting access information..."
    
    # Get public IP
    PUBLIC_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    # Get Open WebUI service info
    OPENWEBUI_PORT=$(kubectl get service -n openwebui open-webui-service -o jsonpath='{.spec.ports[0].port}')
    
    echo "=========================================="
    echo "DEPLOYMENT COMPLETE!"
    echo "=========================================="
    echo "Open WebUI will be available at:"
    echo "http://$PUBLIC_IP"
    echo ""
    echo "To access via port-forward:"
    echo "kubectl port-forward -n openwebui service/open-webui-service 8080:80"
    echo "Then visit: http://localhost:8080"
    echo ""
    echo "To check pod status:"
    echo "kubectl get pods -n openwebui"
    echo ""
    echo "To view logs:"
    echo "kubectl logs -n openwebui -l app=open-webui"
    echo "=========================================="
}

# Main deployment flow
main() {
    check_prerequisites
    azure_login
    deploy_infrastructure
    setup_kubernetes
    load_llama_model
    get_access_info
    
    print_status "Deployment completed successfully!"
}

main "$@"
