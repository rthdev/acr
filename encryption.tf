# User-assigned managed identity for ACR encryption
resource "azurerm_user_assigned_identity" "acr_encryption" {
  name                = "id-acr-encryption-${var.environment}"
  resource_group_name = azurerm_resource_group.acr.name
  location            = azurerm_resource_group.acr.location

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Key Vault for storing encryption keys
resource "azurerm_key_vault" "acr" {
  name                       = "kv-acr-${var.environment}-${random_string.key_vault_suffix.result}"
  location                   = azurerm_resource_group.acr.location
  resource_group_name        = azurerm_resource_group.acr.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  rbac_authorization_enabled = false

  # Network rules to restrict access
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"

    ip_rules = var.admin_ip_allowlist
  }

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Random suffix to ensure Key Vault name uniqueness
resource "random_string" "key_vault_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Access policy for the ACR managed identity
resource "azurerm_key_vault_access_policy" "acr_encryption" {
  key_vault_id = azurerm_key_vault.acr.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.acr_encryption.principal_id

  key_permissions = [
    "Get",
    "UnwrapKey",
    "WrapKey"
  ]
}

# Access policy for Terraform service principal
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.acr.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "Create",
    "Delete",
    "List",
    "Purge",
    "Recover",
    "GetRotationPolicy",
    "SetRotationPolicy"
  ]
}

# Customer-managed encryption key
resource "azurerm_key_vault_key" "acr_encryption" {
  name         = "acr-encryption-key"
  key_vault_id = azurerm_key_vault.acr.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }

  depends_on = [
    azurerm_key_vault_access_policy.terraform
  ]
}

data "azurerm_client_config" "current" {}
