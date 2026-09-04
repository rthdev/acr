# Resource group for the centralised container registry
resource "azurerm_resource_group" "acr" {
  name     = "rg-acr-${var.environment}-${var.location}"
  location = var.location

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Premium ACR with enhanced features enabled
resource "azurerm_container_registry" "main" {
  name                = "acr${var.organisation}${var.environment}"
  resource_group_name = azurerm_resource_group.acr.name
  location            = azurerm_resource_group.acr.location
  sku                 = "Premium"
  admin_enabled       = false

  # Enable anonymous pull for public base images (optional)
  anonymous_pull_enabled = false

  # Network access default action
  public_network_access_enabled = true
  network_rule_bypass_option    = "AzureServices"

  # Enable zone redundancy for high availability
  zone_redundancy_enabled = true

  # Encryption with customer-managed keys
  encryption {
    enabled            = true
    key_vault_key_id   = azurerm_key_vault_key.acr_encryption.id
    identity_client_id = azurerm_user_assigned_identity.acr_encryption.client_id
  }

  # Enable the retention policy for untagged manifests
  retention_policy {
    days    = 7
    enabled = true
  }

  # Trust policy for content trust
  trust_policy {
    enabled = true
  }

  # Quarantine policy to scan images before making them available
  quarantine_policy {
    enabled = true
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.acr_encryption.id
    ]
  }

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }

  depends_on = [
    azurerm_key_vault_access_policy.acr_encryption
  ]
}

# Geo-replication to additional regions
resource "azurerm_container_registry_replication" "replicas" {
  for_each = toset(var.replication_regions)

  name                      = each.value
  container_registry_name   = azurerm_container_registry.main.name
  resource_group_name       = azurerm_resource_group.acr.name
  location                  = each.value
  zone_redundancy_enabled   = true
  regional_endpoint_enabled = true

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
