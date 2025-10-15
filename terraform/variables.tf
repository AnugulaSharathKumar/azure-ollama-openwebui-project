variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "openwebui-aks-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Central India"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "openwebui-aks-cluster"
}

variable "dns_prefix" {
  description = "DNS prefix for AKS"
  type        = string
  default     = "openwebuiaks"
}

variable "admin_username" {
  description = "Admin username for AKS nodes"
  type        = string
  default     = "azureuser"
}

variable "node_count" {
  description = "Number of AKS nodes"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.33.0"
}
