# #############################################################################
# Production Schedule
# #############################################################################

# ------------------------------------------------------------------------------
#                             Tags
# ------------------------------------------------------------------------------

variable "schedule_tag_product" {
  type        = string
  default     = "Inventory Management"
  description = "The product or service that the resources are being created for."
}

variable "schedule_tag_cost_center" {
  type        = string
  default     = "Core"
  description = "Accounting cost center associated with the resource."
}

variable "schedule_tag_criticality" {
  type        = string
  default     = "High"
  description = "The business impact of the resource or supported workload. Valid values are Low, Medium, High, Business Unit Critical, Mission Critical."
}

variable "schedule_tag_disaster_recovery" {
  type        = string
  default     = "Dev"
  description = "Business criticality of the application, workload, or service. Valid values are Mission Critical, Critical, Essential, Dev."
}

locals {
  schedule_tags = {
    Product     = var.schedule_tag_product
    Criticality = var.schedule_tag_criticality
    CostCenter  = "${var.schedule_tag_cost_center}-${var.azure_environment}"
    DR          = var.schedule_tag_disaster_recovery
    Env         = var.azure_environment
  }
}

resource "azurerm_resource_group" "production_schedule" {
  name     = "${module.resource_group.name.abbreviation}-CoolRevive_ProductionSchedule-${var.azure_environment}-${module.azure_regions.region.region_short}"
  location = var.azure_region
  tags     = local.schedule_tags
}





# Local variables
locals {
    current_date = formatdate("YYYY-MM-DD", timestamp())
}

# Storage account for the Production Schedule system (replicating its data store)
resource "azurerm_storage_account" "production_schedule" {
  name                     = "${module.storage_account.name.abbreviation}schedule${var.resource_name_suffix}${var.azure_environment}${module.azure_regions.region.region_short}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = local.tags
}

# Table storage for the Production Schedule system
resource "azurerm_storage_table" "production_schedule" {
  name                 = "ProductionSchedule"
  storage_account_name = azurerm_storage_account.order_next_core.name
}

# Production Schedule table entities
locals {
  core_ids = {
    0 = "ABC123"
    1 = "DEF456"
    2 = "GHI789"
    3 = "JKL987"
    4 = "MNO654"
    5 = "PQR321"
    6 = "STU159"
    7 = "VWX357"
    8 = "ZYA753"
    9 = "DCB951"
  }
}

resource "random_string" "finished_product_id" {
  length  = 10
  special = false
  upper   = true
}

resource "azurerm_storage_table_entity" "production_schedule_pod123" {
  count            = 10
  storage_table_id = azurerm_storage_table.production_schedule.id
  partition_key    = "pod123_${local.current_date}"
  row_key          = count.index + 1
  entity = {
    "podId"    = "pod123",
    "date"     = local.current_date,
    "sequence" = count.index,
    "model"    = "Model 3",
    "coreId"   = local.core_ids[count.index],
    "finishedProductId" = random_string.finished_product_id.result,
    "status"   = "Scheduled",
  }
}








resource "azapi_resource" "production_schedule_server_farm" {
  type                      = "Microsoft.Web/serverfarms@2023-12-01"
  schema_validation_enabled = false
  location                  = var.azure_region
  name                      = "${module.app_service_plan.name.abbreviation}-ProductionScheduleFacade${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id = azurerm_resource_group.production_schedule.id
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

resource "azurerm_storage_account" "production_schedule_function" {
  name                     = "${module.storage_account.name.abbreviation}schdfacade${var.resource_name_suffix}${var.azure_environment}${module.azure_regions.region.region_short}"
  resource_group_name      = azurerm_resource_group.production_schedule.name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.schedule_tags
}

resource "azurerm_storage_container" "production_schedule_deployment_package" {
  name                  = "deploymentpackage"
  storage_account_name  = azurerm_storage_account.production_schedule_function.name
  container_access_type = "private"
}

locals {
    schedule-BlobStorageAndContainer = "${azurerm_storage_account.production_schedule_function.primary_blob_endpoint}deploymentpackage"
}

variable "production_schedule_max_instance_count" {
  type = number
  default = 100
  description = "The maximum number of instances that the Production Schedule Facade function app can scale to."
}

variable "production_schedule_instance_memory" {
  type = number
  default = 2048
  description = "The maximum amount of memory that the Production Schedule Facade function app can use."
}

resource "azapi_resource" "production_schedule_function_app" {
  type                      = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location                  = var.azure_region
  name                      = "${module.function_app.name.abbreviation}-ProductionScheduleFacade${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id = azurerm_resource_group.production_schedule.id
  body = jsonencode({
    kind = "functionapp,linux",
    identity = {
      type: "SystemAssigned"
    }
    properties = {
      serverFarmId = azapi_resource.production_schedule_server_farm.id,
        functionAppConfig = {
          deployment = {
            storage = {
              type = "blobContainer",
              value = local.schedule-BlobStorageAndContainer,
              authentication = {
                type = "SystemAssignedIdentity"
              }
            }
          },
          scaleAndConcurrency = {
            maximumInstanceCount = var.production_schedule_max_instance_count,
            instanceMemoryMB = var.production_schedule_instance_memory
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
              value = azurerm_storage_account.production_schedule_function.name
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
    azapi_resource.production_schedule_server_farm,
    azurerm_application_insights.app_insights,
    azurerm_storage_account.production_schedule_function,
    azurerm_storage_container.production_schedule_deployment_package
  ]
}

data "azurerm_linux_function_app" "production_schedule_wrapper" {
    name = azapi_resource.production_schedule_function_app.name
    resource_group_name = azurerm_resource_group.production_schedule.name
}

resource "azurerm_role_assignment" "production_schedule_function_storage_acccount" {
  scope = azurerm_storage_account.production_schedule_function.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id = data.azurerm_linux_function_app.production_schedule_wrapper.identity.0.principal_id
}

# Role Assignment: Key Vault Secrets User (func-lookupapi)
resource "azurerm_role_assignment" "production_schedule_key_vault_secrets_user" {
  scope                = azurerm_key_vault.remanufacturing.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_linux_function_app.production_schedule_wrapper.identity.*.principal_id[0]
}

# Role Assignment: App Configuration Data Owner (func-lookupapi)
resource "azurerm_role_assignment" "production_schedule_app_configuration_data_owner" {
  scope                = azurerm_app_configuration.remanufacturing.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_linux_function_app.production_schedule_wrapper.identity.*.principal_id[0]
}

resource "azurerm_role_assignment" "production_schedule_storage_blob_contributor" {
  scope                = azurerm_storage_account.production_schedule.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_linux_function_app.production_schedule_wrapper.identity.*.principal_id[0]
}