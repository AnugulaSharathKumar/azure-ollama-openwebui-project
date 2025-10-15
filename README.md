# azure-ollama-openwebui-project

Azure Cloud
 ├── Terraform (IaC)
 │    ├── Resource Group
 │    ├── AKS (Azure Kubernetes Service)
 │    ├── Node Pool (for Ollama + WebUI)
 │    ├── Network + Storage
 │
 ├── K8s Deployment
 │    ├── Open WebUI Pod (frontend)
 │    ├── Ollama Pod (backend, runs Llama 2)
 │    ├── Service (ClusterIP + LoadBalancer)
 │
 └── Public IP -> Access via browser
