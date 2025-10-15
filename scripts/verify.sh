#!/bin/bash

set -e

echo "Verifying Open WebUI deployment..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Set kubeconfig
export KUBECONFIG=./kubeconfig

# Verify pods are running
verify_pods() {
    print_status "Checking pod status..."
    
    kubectl get pods -n openwebui
    
    OLLAMA_READY=$(kubectl get pods -n openwebui -l app=ollama -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')
    OPENWEBUI_READY=$(kubectl get pods -n openwebui -l app=open-webui -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')
    
    if [ "$OLLAMA_READY" != "True" ]; then
        print_error "Ollama pod is not ready"
        exit 1
    fi
    
    if [ "$OPENWEBUI_READY" != "True" ]; then
        print_error "Open WebUI pod is not ready"
        exit 1
    fi
    
    print_status "All pods are running correctly."
}

# Verify services
verify_services() {
    print_status "Checking services..."
    
    kubectl get services -n openwebui
    
    print_status "Services are running."
}

# Test Ollama API
test_ollama() {
    print_status "Testing Ollama API..."
    
    OLLAMA_POD=$(kubectl get pods -n openwebui -l app=ollama -o jsonpath='{.items[0].metadata.name}')
    
    # Test if Ollama is responding
    if kubectl exec -n openwebui $OLLAMA_POD -- curl -s http://localhost:11434/api/tags > /dev/null; then
        print_status "Ollama API is responding correctly."
    else
        print_error "Ollama API is not responding"
        exit 1
    fi
}

# Test Open WebUI
test_openwebui() {
    print_status "Testing Open WebUI..."
    
    OPENWEBUI_POD=$(kubectl get pods -n openwebui -l app=open-webui -o jsonpath='{.items[0].metadata.name}')
    
    # Test if Open WebUI is responding
    if kubectl exec -n openwebui $OPENWEBUI_POD -- curl -s http://localhost:8080 > /dev/null; then
        print_status "Open WebUI is responding correctly."
    else
        print_error "Open WebUI is not responding"
        exit 1
    fi
}

# Check connectivity between services
check_connectivity() {
    print_status "Checking connectivity between Open WebUI and Ollama..."
    
    OPENWEBUI_POD=$(kubectl get pods -n openwebui -l app=open-webui -o jsonpath='{.items[0].metadata.name}')
    
    if kubectl exec -n openwebui $OPENWEBUI_POD -- curl -s http://ollama-service:11434/api/tags > /dev/null; then
        print_status "Connectivity between Open WebUI and Ollama is working."
    else
        print_error "Open WebUI cannot reach Ollama service"
        exit 1
    fi
}

main() {
    verify_pods
    verify_services
    test_ollama
    test_openwebui
    check_connectivity
    
    print_status "All verification tests passed! Deployment is successful."
}

main "$@"
