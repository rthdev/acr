# Log Analytics workspace for ACR diagnostics
resource "azurerm_log_analytics_workspace" "acr" {
  name                = "log-acr-${var.environment}"
  location            = azurerm_resource_group.acr.location
  resource_group_name = azurerm_resource_group.acr.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Diagnostic settings for ACR
resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                       = "acr-diagnostics"
  target_resource_id         = azurerm_container_registry.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.acr.id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Alert for failed authentication attempts
resource "azurerm_monitor_metric_alert" "auth_failures" {
  name                = "acr-auth-failures-${var.environment}"
  resource_group_name = azurerm_resource_group.acr.name
  scopes              = [azurerm_container_registry.main.id]
  description         = "Alert when ACR authentication failures exceed threshold"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.ContainerRegistry/registries"
    metric_name      = "TotalPullCount"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 100

    dimension {
      name     = "StatusCode"
      operator = "Include"
      values   = ["401", "403"]
    }
  }

  action {
    action_group_id = var.security_alert_action_group_id
  }
}

# Alert for storage usage
resource "azurerm_monitor_metric_alert" "storage_usage" {
  name                = "acr-storage-usage-${var.environment}"
  resource_group_name = azurerm_resource_group.acr.name
  scopes              = [azurerm_container_registry.main.id]
  description         = "Alert when ACR storage usage exceeds 80%"
  severity            = 3
  frequency           = "PT1H"
  window_size         = "PT1H"

  criteria {
    metric_namespace = "Microsoft.ContainerRegistry/registries"
    metric_name      = "StorageUsed"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.storage_alert_threshold_bytes
  }

  action {
    action_group_id = var.platform_alert_action_group_id
  }
}

# Workbook for ACR usage analytics
resource "azurerm_application_insights_workbook" "acr_usage" {
  name                = "workbook-acr-usage-${var.environment}"
  resource_group_name = azurerm_resource_group.acr.name
  location            = azurerm_resource_group.acr.location
  display_name        = "ACR Usage Analytics"

  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type = 1
        content = {
          json = "## Container Registry Usage Analytics\n\nThis workbook provides insights into registry usage, image pulls, authentication events, and storage consumption."
        }
      },
      {
        type = 3
        content = {
          version      = "KqlItem/1.0"
          query        = "ContainerRegistryRepositoryEvents\n| where TimeGenerated > ago(7d)\n| summarize PullCount = countif(OperationName == 'Pull'), PushCount = countif(OperationName == 'Push') by bin(TimeGenerated, 1h), Repository\n| render timechart"
          size         = 0
          title        = "Pull and Push Operations by Repository (Last 7 Days)"
          queryType    = 0
          resourceType = "microsoft.operationalinsights/workspaces"
        }
      }
    ]
  })

  tags = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
