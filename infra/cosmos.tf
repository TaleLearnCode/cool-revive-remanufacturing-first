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