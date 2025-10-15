# Random suffix for unique names
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

# Resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_group_name}-${random_integer.suffix.result}"
  location = var.location
  tags = {
    environment = "openwebui-ollama"
    deployed-by = "terraform"
  }
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "openwebuiacr${random_integer.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Data source to get available Kubernetes versions
data "azurerm_kubernetes_service_versions" "current" {
  location = var.location
}

# Get the specified Kubernetes version or latest available
locals {
  available_versions = data.azurerm_kubernetes_service_versions.current.versions
  kubernetes_version = contains(local.available_versions, var.kubernetes_version) ? var.kubernetes_version : local.available_versions[length(local.available_versions) - 1]
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.cluster_name}-${random_integer.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.dns_prefix}${random_integer.suffix.result}"
  kubernetes_version  = local.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.vm_size
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = false
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
    network_policy = "calico"
    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"
  }

  tags = {
    environment = "openwebui-ollama"
    deployed-by = "terraform"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "logs-${var.cluster_name}-${random_integer.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Role assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.main.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate)
  }
}
