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
  name                = lower("${module.cosmos_account.name.abbreviation}-CoolRevive${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}")
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