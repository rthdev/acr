variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
}

variable "location" {
  description = "Primary Azure region"
  type        = string
  default     = "uksouth"
}

variable "organisation" {
  description = "Organisation name for resource naming"
  type        = string
}

variable "replication_regions" {
  description = "Additional regions for ACR geo-replication"
  type        = list(string)
  default     = ["ukwest", "northeurope"]
}

variable "hub_vnet_id" {
  description = "Resource ID of hub VNet"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of hub VNet"
  type        = string
}

variable "hub_vnet_resource_group" {
  description = "Resource group of hub VNet"
  type        = string
}

variable "acr_endpoint_subnet_cidr" {
  description = "CIDR block for ACR private endpoint subnet"
  type        = string
}

variable "aks_spoke_vnet_ids" {
  description = "Map of AKS spoke VNet IDs for DNS zone linking"
  type        = map(string)
  default     = {}
}

variable "aks_clusters" {
  description = "Map of AKS cluster names for managed identity creation"
  type        = map(string)
  default     = {}
}

variable "container_app_environments" {
  description = "Map of Container App environment names"
  type        = map(string)
  default     = {}
}

variable "github_actions_ip_ranges" {
  description = "IP ranges for GitHub Actions runners"
  type        = list(string)
  default = [
    # These are example ranges - use actual GitHub IP ranges
    "140.82.112.0/20",
    "143.55.64.0/20",
    "185.199.108.0/22",
    "192.30.252.0/22"
  ]
}

variable "admin_ip_allowlist" {
  description = "IP addresses allowed to access Key Vault"
  type        = list(string)
}

variable "security_alert_action_group_id" {
  description = "Action group ID for security alerts"
  type        = string
}

variable "platform_alert_action_group_id" {
  description = "Action group ID for platform alerts"
  type        = string
}

variable "storage_alert_threshold_bytes" {
  description = "Storage threshold for alerts in bytes"
  type        = number
  default     = 1099511627776 # 1TB
}

variable "github_org" {
  description = "GitHub organisation name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}
