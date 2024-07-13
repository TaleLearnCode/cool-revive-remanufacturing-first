# #############################################################################
# Warehouse
# #############################################################################

# ------------------------------------------------------------------------------
#                             Tags
# ------------------------------------------------------------------------------

variable "warehouse_tag_product" {
  type        = string
  default     = "Warehouse"
  description = "The product or service that the resources are being created for."
}

variable "warehouse_tag_cost_center" {
  type        = string
  default     = "Core"
  description = "Accounting cost center associated with the resource."
}

variable "warehouse_tag_criticality" {
  type        = string
  default     = "High"
  description = "The business impact of the resource or supported workload. Valid values are Low, Medium, High, Business Unit Critical, Mission Critical."
}

variable "warehouse_tag_disaster_recovery" {
  type        = string
  default     = "Dev"
  description = "Business criticality of the application, workload, or service. Valid values are Mission Critical, Critical, Essential, Dev."
}

locals {
  warehouse_tags = {
    Product     = var.warehouse_tag_product
    Criticality = var.warehouse_tag_criticality
    CostCenter  = "${var.warehouse_tag_cost_center}-${var.azure_environment}"
    DR          = var.warehouse_tag_disaster_recovery
    Env         = var.azure_environment
  }
}

resource "azurerm_resource_group" "warehouse" {
  name     = "${module.resource_group.name.abbreviation}-CoolRevive_Warehouse-${var.azure_environment}-${module.azure_regions.region.region_short}"
  location = var.azure_region
  tags     = local.warehouse_tags
}





# Storage account for the Warehouse system (replicating its data store)
resource "azurerm_storage_account" "warehouse" {
  name                     = "${module.storage_account.name.abbreviation}warehouse${var.resource_name_suffix}${var.azure_environment}${module.azure_regions.region.region_short}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = local.tags
}

# Table storage for the Warehouse system
resource "azurerm_storage_table" "warehouse" {
  name                 = "Warehouse"
  storage_account_name = azurerm_storage_account.order_next_core.name
}

resource "azapi_resource" "warehouse_server_farm" {
  type                      = "Microsoft.Web/serverfarms@2023-12-01"
  schema_validation_enabled = false
  location                  = var.azure_region
  name                      = "${module.app_service_plan.name.abbreviation}-Warehouse${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id = azurerm_resource_group.warehouse.id
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

resource "azurerm_storage_account" "warehouse_function" {
  name                     = "${module.storage_account.name.abbreviation}conveyf${var.resource_name_suffix}${var.azure_environment}${module.azure_regions.region.region_short}"
  resource_group_name      = azurerm_resource_group.warehouse.name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.warehouse_tags
}

resource "azurerm_storage_container" "warehouse_deployment_package" {
  name                  = "deploymentpackage"
  storage_account_name  = azurerm_storage_account.warehouse_function.name
  container_access_type = "private"
}

locals {
    warehouse-BlobStorageAndContainer = "${azurerm_storage_account.warehouse_function.primary_blob_endpoint}deploymentpackage"
}

variable "warehouse_max_instance_count" {
  type = number
  default = 100
  description = "The maximum number of instances that the Warehouse function app can scale to."
}

variable "warehouse_instance_memory" {
  type = number
  default = 2048
  description = "The maximum amount of memory that the Warehouse function app can use."
}

resource "azapi_resource" "warehouse_function_app" {
  type                      = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location                  = var.azure_region
  name                      = "${module.function_app.name.abbreviation}-Warehouse${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id = azurerm_resource_group.warehouse.id
  body = jsonencode({
    kind = "functionapp,linux",
    identity = {
      type: "SystemAssigned"
    }
    properties = {
      serverFarmId = azapi_resource.warehouse_server_farm.id,
        functionAppConfig = {
          deployment = {
            storage = {
              type = "blobContainer",
              value = local.warehouse-BlobStorageAndContainer,
              authentication = {
                type = "SystemAssignedIdentity"
              }
            }
          },
          scaleAndConcurrency = {
            maximumInstanceCount = var.warehouse_max_instance_count,
            instanceMemoryMB = var.warehouse_instance_memory
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
              value = azurerm_storage_account.warehouse_function.name
            },
            {
              name = "APPLICATIONINSIGHTS_CONNECTION_STRING",
              value = azurerm_application_insights.app_insights.connection_string
            },
            {
              name = "ServiceBusConnectionString",
              value = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.service_bus_connection_string.key}; Label=${var.azure_environment})"
            },
          ]
        }
      }
  })
  depends_on = [
    azapi_resource.warehouse_server_farm,
    azurerm_application_insights.app_insights,
    azurerm_storage_account.warehouse_function,
    azurerm_storage_container.warehouse_deployment_package
  ]
}

data "azurerm_linux_function_app" "warehouse_wrapper" {
    name = azapi_resource.warehouse_function_app.name
    resource_group_name = azurerm_resource_group.warehouse.name
}

resource "azurerm_role_assignment" "warehouse_function_storage_acccount" {
  scope = azurerm_storage_account.warehouse_function.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id = data.azurerm_linux_function_app.warehouse_wrapper.identity.0.principal_id
}

# Role Assignment: Key Vault Secrets User (func-lookupapi)
resource "azurerm_role_assignment" "warehouse_key_vault_secrets_user" {
  scope                = azurerm_key_vault.remanufacturing.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_linux_function_app.warehouse_wrapper.identity.*.principal_id[0]
}

# Role Assignment: App Configuration Data Owner (func-lookupapi)
resource "azurerm_role_assignment" "warehouse_app_configuration_data_owner" {
  scope                = azurerm_app_configuration.remanufacturing.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_linux_function_app.warehouse_wrapper.identity.*.principal_id[0]
}

resource "azurerm_role_assignment" "warehouse_storage_blob_contributor" {
  scope                = azurerm_storage_account.warehouse.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_linux_function_app.warehouse_wrapper.identity.*.principal_id[0]
}