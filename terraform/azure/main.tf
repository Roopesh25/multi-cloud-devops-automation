# ============================
# AZURE MAIN.TF (Refactored to Use variables.tf)
# ============================

provider "azurerm" {
  features {}
}

# --- Resource Group ---
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# --- Virtual Network and Subnet ---
resource "azurerm_virtual_network" "main" {
  name                = "multi-cloud-vnet"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.aks_subnet_prefix
}

# --- Network Security Group ---
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "aks-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# --- Log Analytics Workspace ---
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# --- AKS Cluster ---
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "multi-cloud-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "multi-cloud-aks"

  default_node_pool {
    name           = "default"
    node_count     = var.aks_node_count
    vm_size        = var.aks_node_size
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
    azure_active_directory {
      managed                = true
      admin_group_object_ids = ["<AAD-GROUP-ID>"]
    }
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    }
  }
}

# --- ACR ---
resource "azurerm_container_registry" "acr" {
  name                            = var.acr_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  sku                             = "Standard"
  admin_enabled                   = false
  public_network_access_enabled   = false

  network_rule_set {
    default_action = "Deny"
  }
}

# --- Role Assignment: ACR Pull for AKS ---
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

# --- Private Endpoint for ACR ---
resource "azurerm_private_endpoint" "acr_endpoint" {
  name                = "acr-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.aks_subnet.id

  private_service_connection {
    name                           = "acr-privatesc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }
}

# --- Private DNS Zone + A Record ---
resource "azurerm_private_dns_zone" "acr_dns" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_dns_link" {
  name                  = "acr-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_dns.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}

resource "azurerm_private_dns_a_record" "acr_record" {
  name                = azurerm_container_registry.acr.name
  zone_name           = azurerm_private_dns_zone.acr_dns.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.acr_endpoint.private_service_connection[0].private_ip_address]
}
