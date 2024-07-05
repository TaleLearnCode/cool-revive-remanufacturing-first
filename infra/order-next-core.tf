# #############################################################################
# Order Next Core
# #############################################################################

# ------------------------------------------------------------------------------
# Step 1: Send Next Core Request to Warehouse Mesaging
# ------------------------------------------------------------------------------

# ebt-SendNextCoreRequestToWarehouseXXX-dev-cus
resource "azurerm_eventgrid_topic" "send_next_core_request_to_warehouse" {
  name                = "${module.event_grid_topic.name.abbreviation}-SendNextCoreRequestToWarehouse${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  identity {
    type = "SystemAssigned"
  }
  tags = local.tags
}

# sbt-OrderNextCore-dev-cus
resource "azurerm_servicebus_topic" "order_next_core" {
  name                      = "${module.service_bus_topic.name.abbreviation}-OrderNextCore-${var.azure_environment}-${module.azure_regions.region.region_short}"
  namespace_id              = azurerm_servicebus_namespace.remanufacturing.id
  support_ordering          = true
  enable_batched_operations = true
  depends_on = [ 
    azurerm_servicebus_namespace.remanufacturing
   ]
}

## SendNextCoreRequestToWarehouse (ebt-SendNextCoreRequestToWarehouseXXX-dev-cus) -> OrderNextCore (sbt-OrderNextCore-dev-cus
#resource "azurerm_eventgrid_event_subscription" "send_next_core_request_to_warehouse" {
#  name                          = "SendNextCoreRequestToWarehouse"
#  scope                         = azurerm_eventgrid_topic.send_next_core_request_to_warehouse.id
#  service_bus_queue_endpoint_id = azurerm_servicebus_topic.order_next_core.id
#  depends_on = [
#    azurerm_servicebus_topic.order_next_core,
#    azurerm_eventgrid_topic.send_next_core_request_to_warehouse
#  ]
#}