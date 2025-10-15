#!/bin/bash
set -e

echo "=== Deploying Azure AKS Infrastructure ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_tool() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

print_status "Checking prerequisites..."
check_tool az || exit 1
check_tool kubectl || exit 1
check_tool terraform || exit 1

# Check Azure login
print_status "Checking Azure login..."
az account show > /dev/null 2>&1 || {
    print_warning "Please log in to Azure..."
    az login
}

# Clean previous deployments
print_status "Cleaning previous deployments..."
cd terraform
rm -rf .terraform .terraform.lock.hcl terraform.tfstate* plan.out kubeconfig 2>/dev/null || true

# Initialize Terraform with retries
print_status "Initializing Terraform..."
for attempt in {1..3}; do
    if terraform init -upgrade; then
        print_success "Terraform initialized successfully!"
        break
    fi
    if [ $attempt -eq 3 ]; then
        print_error "Terraform init failed after 3 attempts"
        exit 1
    fi
    print_warning "Terraform init attempt $attempt failed, retrying..."
    sleep 10
done

# Plan and apply
print_status "Planning deployment..."
terraform plan -out=plan.out

print_status "Applying infrastructure (this will take 10-15 minutes)..."
terraform apply -auto-approve plan.out

# Get kubeconfig
print_status "Getting kubeconfig..."
terraform output -raw kube_config > ../kubeconfig

cd ..

# Test cluster connection
print_status "Testing cluster connection..."
export KUBECONFIG=./kubeconfig
if kubectl cluster-info; then
    print_success "Cluster connection successful!"
else
    print_error "Failed to connect to cluster"
    exit 1
fi

print_success "Infrastructure deployment completed!"
echo ""
echo "Cluster information:"
kubectl get nodes
