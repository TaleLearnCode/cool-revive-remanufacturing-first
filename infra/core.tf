# #############################################################################
# API Management
# #############################################################################

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "apim_publisher_name" {
  type        = string
  default     = "Nebraska.Code"
  description = "The name of the publisher of the API Management instance."
}

variable "apim_publisher_email" {
  type        = string
  default     = "chad.green@chadgreen.com"
  description = "The email address of the publisher of the API Management instance."
}

variable "apim_sku_name" {
  type        = string
  default     = "Developer_1"
  description = "The SKU of the API Management instance."
}

# -----------------------------------------------------------------------------
# API Management Service Instance
# -----------------------------------------------------------------------------

resource "azurerm_api_management" "apim" {
  name                = lower("${module.api_management.name.abbreviation}-${var.company_name}-${var.azure_environment}-${module.azure_regions.region.region_short}")
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name
}

# #############################################################################
# CosmosDB Account
# #############################################################################

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = lower("${module.cosmos_account.name.abbreviation}-Remanufacturing${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}")
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  consistency_policy {
    consistency_level = "Session"
  }
  geo_location {
    location          = data.azurerm_resource_group.rg.location
    failover_priority = 0
  }
  tags = local.tags
}

resource "azurerm_app_configuration_key" "cosmos_endpoint" {
  configuration_store_id = azurerm_app_configuration.remanufacturing.id
  key                    = "ServiceBus:ConnectionString"
  label                  = var.azure_environment
  value                  = azurerm_cosmosdb_account.cosmos.endpoint
}

resource "azurerm_role_definition" "cosmos_read_write" {
  name        = "Cosmos DB Account Read/Write"
  scope       = data.azurerm_subscription.current.id
  description = "Can read and write to Cosmos DB Account"
  permissions {
    actions = [
      "Microsoft.DocumentDB/databaseAccounts/services/read",
      "Microsoft.DocumentDB/databaseAccounts/services/write",
      "Microsoft.DocumentDB/databaseAccounts/services/delete"
    ]
  }
}



# #############################################################################
# Service Bus
# #############################################################################

resource "azurerm_servicebus_namespace" "remanufacturing" {
  name                = lower("${module.service_bus_namespace.name.abbreviation}-${var.system_name}${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}")
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_key_vault_secret" "service_bus_connection_string" {
  name         = "ServiceBus-ConnectionString"
  value        = azurerm_communication_service.notification_manager.primary_connection_string
  key_vault_id = azurerm_key_vault.remanufacturing.id
}

resource "azurerm_app_configuration_key" "service_bus_connection_string" {
  configuration_store_id = azurerm_app_configuration.remanufacturing.id
  key                    = "ServiceBus:ConnectionString"
  type                   = "vault"
  label                  = var.azure_environment
  vault_key_reference    = azurerm_key_vault_secret.service_bus_connection_string.versionless_id
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}


# #############################################################################
# Log Analytics Workspace
# #############################################################################

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = lower("${module.log_analytics_workspace.name.abbreviation}-CoolRevive${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}")
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# #############################################################################
# Application Insights
# #############################################################################

resource "azurerm_application_insights" "app_insights" {
  name                = lower("${module.application_insights.name.abbreviation}-CoolRevive${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}")
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.log_analytics.id
  application_type    = "web"
  tags                = local.tags
}

# #############################################################################
# Key Vault
# #############################################################################

resource "azurerm_key_vault" "remanufacturing" {
  name                        = lower("${module.key_vault.name.abbreviation}-Reman${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}")
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name                    = "standard"
  enable_rbac_authorization  = true
}

resource "azurerm_role_assignment" "key_vault_administrator" {
  scope                = azurerm_key_vault.remanufacturing.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# #############################################################################
# App Configuration
# #############################################################################

resource "azurerm_app_configuration" "remanufacturing" {
  name                       = lower("${module.app_config.name.abbreviation}-Remanufacturing${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}")
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  sku                        = "standard"
  local_auth_enabled         = true
  public_network_access      = "Enabled"
  purge_protection_enabled   = false
  soft_delete_retention_days = 1
  tags = local.tags
}

# Role Assignment: 'App Configuration Data Owner' to current Terraform user
resource "azurerm_role_assignment" "app_config_data_owner" {
  scope                = azurerm_app_configuration.remanufacturing.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}