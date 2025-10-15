output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "kube_config" {
  description = "Kubernetes config file"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "host" {
  description = "Kubernetes cluster host"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.host
}
