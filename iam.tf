# Service principal for GitHub Actions with OIDC federated credentials
resource "azuread_application" "github_actions" {
  display_name = "sp-acr-github-actions-${var.environment}"
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

# Federated identity credential for GitHub OIDC (main branch)
resource "azuread_application_federated_identity_credential" "github_actions_main" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-main-branch"
  description    = "Federated credential for GitHub Actions main branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
}

# Federated identity credential for GitHub OIDC (pull requests)
resource "azuread_application_federated_identity_credential" "github_actions_pr" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-pull-requests"
  description    = "Federated credential for GitHub Actions pull requests"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repo}:pull_request"
}

# Federated identity credential for GitHub OIDC (develop branch)
resource "azuread_application_federated_identity_credential" "github_actions_develop" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-develop-branch"
  description    = "Federated credential for GitHub Actions develop branch"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/develop"
}

# Role assignment for GitHub Actions - push access
resource "azurerm_role_assignment" "github_actions_push" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Managed identities for AKS clusters
resource "azurerm_user_assigned_identity" "aks_clusters" {
  for_each = var.aks_clusters

  name                = "id-aks-${each.key}-${var.environment}"
  resource_group_name = azurerm_resource_group.acr.name
  location            = azurerm_resource_group.acr.location

  tags = {
    environment = var.environment
    managed_by  = "terraform"
    cluster     = each.key
  }
}

# Role assignment for AKS - pull access
resource "azurerm_role_assignment" "aks_pull" {
  for_each = azurerm_user_assigned_identity.aks_clusters

  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = each.value.principal_id
}

# Managed identities for Container Apps
resource "azurerm_user_assigned_identity" "container_apps" {
  for_each = var.container_app_environments

  name                = "id-containerapp-${each.key}-${var.environment}"
  resource_group_name = azurerm_resource_group.acr.name
  location            = azurerm_resource_group.acr.location

  tags = {
    environment = var.environment
    managed_by  = "terraform"
    app_env     = each.key
  }
}

# Role assignment for Container Apps - pull access
resource "azurerm_role_assignment" "container_apps_pull" {
  for_each = azurerm_user_assigned_identity.container_apps

  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = each.value.principal_id
}

# Custom role for team-specific repository access (example)
resource "azurerm_role_definition" "team_repository_contributor" {
  name  = "ACR Team Repository Contributor"
  scope = azurerm_container_registry.main.id

  permissions {
    actions = [
      "Microsoft.ContainerRegistry/registries/pull/read",
      "Microsoft.ContainerRegistry/registries/push/write",
      "Microsoft.ContainerRegistry/registries/artifacts/delete"
    ]

    data_actions = [
      "Microsoft.ContainerRegistry/registries/*/read",
      "Microsoft.ContainerRegistry/registries/*/write",
      "Microsoft.ContainerRegistry/registries/*/delete"
    ]
  }

  assignable_scopes = [
    azurerm_container_registry.main.id
  ]
}
