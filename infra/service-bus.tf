# #############################################################################
# Service Bus
# #############################################################################

resource "azurerm_servicebus_namespace" "catalog" {
  name                = lower("${module.service_bus_namespace.name.abbreviation}-${var.system_name}${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}")
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = local.tags
}