# #############################################################################
# Inventory Management
# #############################################################################

# ------------------------------------------------------------------------------
#                             Tags
# ------------------------------------------------------------------------------

variable "inventory_tag_product" {
  type        = string
  default     = "Inventory Management"
  description = "The product or service that the resources are being created for."
}

variable "inventory_tag_cost_center" {
  type        = string
  default     = "Core"
  description = "Accounting cost center associated with the resource."
}

variable "inventory_tag_criticality" {
  type        = string
  default     = "High"
  description = "The business impact of the resource or supported workload. Valid values are Low, Medium, High, Business Unit Critical, Mission Critical."
}

variable "inventory_tag_disaster_recovery" {
  type        = string
  default     = "Dev"
  description = "Business criticality of the application, workload, or service. Valid values are Mission Critical, Critical, Essential, Dev."
}

locals {
  inventory_tags = {
    Product     = var.inventory_tag_product
    Criticality = var.inventory_tag_criticality
    CostCenter  = "${var.inventory_tag_cost_center}-${var.azure_environment}"
    DR          = var.inventory_tag_disaster_recovery
    Env         = var.azure_environment
  }
}

resource "azurerm_resource_group" "inventory_management" {
  name     = "${module.resource_group.name.abbreviation}-CoolRevive_InventoryManagement-${var.azure_environment}-${module.azure_regions.region.region_short}"
  location = var.azure_region
  tags     = local.inventory_tags
}





resource "azapi_resource" "inventory_management_server_farm" {
  type                      = "Microsoft.Web/serverfarms@2023-12-01"
  schema_validation_enabled = false
  location                  = var.azure_region
  name                      = "${module.app_service_plan.name.abbreviation}-InventoryManagment${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id = azurerm_resource_group.inventory_management.id
  body = jsonencode({
      kind = "functionapp",
      sku = {
        tier = "FlexConsumption",
        name = "FC1"
      },
      properties = {
        reserved = true
      }
  })
}

resource "azurerm_storage_account" "inventory_management_function" {
  name                     = "${module.storage_account.name.abbreviation}inventory${var.resource_name_suffix}${var.azure_environment}${module.azure_regions.region.region_short}"
  resource_group_name      = azurerm_resource_group.inventory_management.name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.inventory_tags
}

resource "azurerm_storage_container" "inventory_management_deployment_package" {
  name                  = "deploymentpackage"
  storage_account_name  = azurerm_storage_account.inventory_management_function.name
  container_access_type = "private"
}

locals {
    inventory-BlobStorageAndContainer = "${azurerm_storage_account.inventory_management_function.primary_blob_endpoint}deploymentpackage"
}

variable "inventory_management_max_instance_count" {
  type = number
  default = 100
  description = "The maximum number of instances that the Inventory Management function app can scale to."
}

variable "inventory_management_instance_memory" {
  type = number
  default = 2048
  description = "The maximum amount of memory that the Inventory Management function app can use."
}

resource "azapi_resource" "inventory_management_function_app" {
  type                      = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location                  = var.azure_region
  name                      = "${module.function_app.name.abbreviation}-InventoryManagment${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id = azurerm_resource_group.inventory_management.id
  body = jsonencode({
    kind = "functionapp,linux",
    identity = {
      type: "SystemAssigned"
    }
    properties = {
      serverFarmId = azapi_resource.inventory_management_server_farm.id,
        functionAppConfig = {
          deployment = {
            storage = {
              type = "blobContainer",
              value = local.inventory-BlobStorageAndContainer,
              authentication = {
                type = "SystemAssignedIdentity"
              }
            }
          },
          scaleAndConcurrency = {
            maximumInstanceCount = var.inventory_management_max_instance_count,
            instanceMemoryMB = var.inventory_management_instance_memory
          },
          runtime = { 
            name = "dotnet-isolated"
            version = "8.0"
          }
        },
        siteConfig = {
          appSettings = [
            {
              name = "AzureWebJobsStorage__accountName",
              value = azurerm_storage_account.inventory_management_function.name
            },
            {
              name = "APPLICATIONINSIGHTS_CONNECTION_STRING",
              value = azurerm_application_insights.app_insights.connection_string
            },
            {
              name = "ServiceBusConnectionString",
              value = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.service_bus_connection_string.key}; Label=${var.azure_environment})"
            },
            {
              name = "OrderNextCore_TopicName",
              value = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.order_next_core_topic_name.key}; Label=${var.azure_environment})"
            },
            {
              name = "OrderNextCoreInventoryManagement",
              value = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.order_next_core_inventory_management_subscription_name.key}; Label=${var.azure_environment})"
            }
          ]
        }
      }
  })
  depends_on = [
    azapi_resource.inventory_management_server_farm,
    azurerm_application_insights.app_insights,
    azurerm_storage_account.inventory_management_function,
    azurerm_storage_container.inventory_management_deployment_package
  ]
}

data "azurerm_linux_function_app" "inventory_management_wrapper" {
    name = azapi_resource.inventory_management_function_app.name
    resource_group_name = azurerm_resource_group.inventory_management.name
}

resource "azurerm_role_assignment" "inventory_management_function_storage_acccount" {
  scope = azurerm_storage_account.inventory_management_function.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id = data.azurerm_linux_function_app.inventory_management_wrapper.identity.0.principal_id
}

# Role Assignment: Key Vault Secrets User (func-lookupapi)
resource "azurerm_role_assignment" "inventory_management_key_vault_secrets_user" {
  scope                = azurerm_key_vault.remanufacturing.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_linux_function_app.inventory_management_wrapper.identity.*.principal_id[0]
}

# Role Assignment: App Configuration Data Owner (func-lookupapi)
resource "azurerm_role_assignment" "inventory_management_app_configuration_data_owner" {
  scope                = azurerm_app_configuration.remanufacturing.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_linux_function_app.inventory_management_wrapper.identity.*.principal_id[0]
}


resource "azurerm_role_assignment" "inventory_management_cosmos_read_write" {
  scope                = azurerm_app_configuration.remanufacturing.id
  role_definition_name = azurerm_role_definition.cosmos_read_write.name
  principal_id         = data.azurerm_linux_function_app.inventory_management_wrapper.identity.*.principal_id[0]
}

resource "azurerm_servicebus_subscription" "order_next_core_inventory_management" {
  name               = "${module.service_bus_topic_subscription.name.abbreviation}-OrderNextCore_Inventory-${var.azure_environment}-${module.azure_regions.region.region_short}"
  topic_id           = azurerm_servicebus_topic.next_core_in_transit.id
  max_delivery_count = 1
  depends_on = [ 
    azurerm_servicebus_topic.next_core_in_transit
   ]
}

resource "azurerm_app_configuration_key" "order_next_core_inventory_management_subscription_name" {
  configuration_store_id = azurerm_app_configuration.remanufacturing.id
  key                    = "ServiceBus:Topics:OrderNextCore:Subscriptions:InventoryManagement"
  label                  = var.azure_environment
  value                  = azurerm_servicebus_subscription.order_next_core_inventory_management.name
}
