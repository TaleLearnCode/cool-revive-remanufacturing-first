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

# ------------------------------------------------------------------------------
# Step 2: Send Next Core Response to Warehouse Mesaging
# ------------------------------------------------------------------------------

# Storage account for the OrderNextCore Azure Function app
resource "azurerm_storage_account" "order_next_core" {
  name                     = "${module.storage_account.name.abbreviation}onc${var.resource_name_suffix}${var.azure_environment}${module.azure_regions.region.region_short}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = local.tags
}

# App Service Plan for the OrderNextCore Azure Function app
resource "azurerm_service_plan" "order_next_core" {
  name                = "${module.app_service_plan.name.abbreviation}-OrderNextCore${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.tags
}

# OrderNextCore Azure Function app
resource "azurerm_linux_function_app" "order_next_core" {
  name                       = "${module.function_app.name.abbreviation}-OrderNextCore${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  storage_account_name       = azurerm_storage_account.order_next_core.name
  storage_account_access_key = azurerm_storage_account.order_next_core.primary_access_key
  service_plan_id            = azurerm_service_plan.order_next_core.id
  tags                       = local.tags
  identity {
    type = "SystemAssigned"
  }
  site_config {
    application_stack {
      dotnet_version              = "8.0"
      use_dotnet_isolated_runtime = true
    }
    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
    application_insights_connection_string = azurerm_application_insights.app_insights.instrumentation_key
    application_insights_key               = azurerm_application_insights.app_insights.instrumentation_key
  }
}