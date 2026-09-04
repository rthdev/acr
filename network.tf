# Private DNS zone for ACR
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.acr.name

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Link DNS zone to hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "acr_hub" {
  name                  = "acr-hub-link"
  resource_group_name   = azurerm_resource_group.acr.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Link DNS zone to AKS spoke VNets
resource "azurerm_private_dns_zone_virtual_network_link" "acr_aks_spokes" {
  for_each = var.aks_spoke_vnet_ids

  name                  = "acr-aks-${each.key}-link"
  resource_group_name   = azurerm_resource_group.acr.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = each.value
  registration_enabled  = false

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Subnet for ACR private endpoint
resource "azurerm_subnet" "acr_endpoints" {
  name                 = "snet-acr-endpoints"
  resource_group_name  = var.hub_vnet_resource_group
  virtual_network_name = var.hub_vnet_name
  address_prefixes     = [var.acr_endpoint_subnet_cidr]

  private_endpoint_network_policies_enabled = false
}

# Private endpoint for ACR
resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr-${var.environment}"
  location            = azurerm_resource_group.acr.location
  resource_group_name = azurerm_resource_group.acr.name
  subnet_id           = azurerm_subnet.acr_endpoints.id

  private_service_connection {
    name                           = "acr-private-connection"
    private_connection_resource_id = azurerm_container_registry.main.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Network rules for ACR - allow GitHub Actions
resource "azurerm_container_registry_network_rule_set" "main" {
  container_registry_id = azurerm_container_registry.main.id

  default_action = "Deny"

  # Allow GitHub Actions IP ranges for image push
  ip_rule = [
    for cidr in var.github_actions_ip_ranges : {
      action   = "Allow"
      ip_range = cidr
    }
  ]

  # Allow Azure services
  virtual_network = []
}
