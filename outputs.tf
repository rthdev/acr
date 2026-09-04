output "registry_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.main.name
}

output "registry_id" {
  description = "Resource ID of the container registry"
  value       = azurerm_container_registry.main.id
}

output "registry_login_server" {
  description = "Login server URL for the registry"
  value       = azurerm_container_registry.main.login_server
}

output "github_actions_client_id" {
  description = "Client ID for GitHub Actions service principal"
  value       = azuread_application.github_actions.client_id
}

output "github_actions_tenant_id" {
  description = "Azure AD tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "github_actions_subscription_id" {
  description = "Azure subscription ID"
  value       = data.azurerm_client_config.current.subscription_id
}

output "aks_identity_ids" {
  description = "Map of AKS managed identity resource IDs"
  value = {
    for k, v in azurerm_user_assigned_identity.aks_clusters : k => v.id
  }
}

output "container_app_identity_ids" {
  description = "Map of Container App managed identity resource IDs"
  value = {
    for k, v in azurerm_user_assigned_identity.container_apps : k => v.id
  }
}

output "private_endpoint_ip" {
  description = "Private IP address of the ACR endpoint"
  value       = azurerm_private_endpoint.acr.private_service_connection[0].private_ip_address
}
