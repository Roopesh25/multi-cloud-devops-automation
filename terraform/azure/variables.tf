# ============================
# variables.tf for Azure Deployment
# ============================

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "multi-cloud-rg"
}

variable "vnet_address_space" {
  description = "CIDR block for the VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "aks_subnet_prefix" {
  description = "CIDR block for the AKS subnet"
  type        = list(string)
  default     = ["10.1.1.0/24"]
}

variable "aks_node_count" {
  description = "Number of nodes in AKS"
  type        = number
  default     = 2
}

variable "aks_node_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "acr_name" {
  description = "Name for Azure Container Registry"
  type        = string
  default     = "multicloudacr"
}

variable "log_analytics_name" {
  description = "Name of Log Analytics workspace"
  type        = string
  default     = "aks-log-analytics"
}

# ============================
# outputs.tf for Azure Deployment
# ============================

output "azure_aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "azure_aks_kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "azure_acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "azure_resource_group" {
  value = azurerm_resource_group.main.name
}

output "azure_vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "azure_private_dns_zone" {
  value = azurerm_private_dns_zone.acr_dns.name
}

output "azure_private_endpoint_ip" {
  value = azurerm_private_endpoint.acr_endpoint.private_service_connection[0].private_ip_address
}
