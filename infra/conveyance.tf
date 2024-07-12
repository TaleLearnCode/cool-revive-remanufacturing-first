# #############################################################################
# Conveyance
# #############################################################################

# ------------------------------------------------------------------------------
#                             Tags
# ------------------------------------------------------------------------------

variable "conveyance_tag_product" {
  type        = string
  default     = "Conveyance"
  description = "The product or service that the resources are being created for."
}

variable "conveyance_tag_cost_center" {
  type        = string
  default     = "Core"
  description = "Accounting cost center associated with the resource."
}

variable "conveyance_tag_criticality" {
  type        = string
  default     = "High"
  description = "The business impact of the resource or supported workload. Valid values are Low, Medium, High, Business Unit Critical, Mission Critical."
}

variable "conveyance_tag_disaster_recovery" {
  type        = string
  default     = "Dev"
  description = "Business criticality of the application, workload, or service. Valid values are Mission Critical, Critical, Essential, Dev."
}

locals {
  conveyance_tags = {
    Product     = var.conveyance_tag_product
    Criticality = var.conveyance_tag_criticality
    CostCenter  = "${var.conveyance_tag_cost_center}-${var.azure_environment}"
    DR          = var.conveyance_tag_disaster_recovery
    Env         = var.azure_environment
  }
}

resource "azurerm_resource_group" "conveyance" {
  name     = "${module.resource_group.name.abbreviation}-CoolRevive_Conveyance-${var.azure_environment}-${module.azure_regions.region.region_short}"
  location = var.azure_region
  tags     = local.conveyance_tags
}





# Storage account for the Conveyance system (replicating its data store)
resource "azurerm_storage_account" "conveyance" {
  name                     = "${module.storage_account.name.abbreviation}convey${var.resource_name_suffix}${var.azure_environment}${module.azure_regions.region.region_short}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = local.tags
}

# Table storage for the Conveyance system
resource "azurerm_storage_table" "conveyance" {
  name                 = "Conveyance"
  storage_account_name = azurerm_storage_account.order_next_core.name
}

resource "azapi_resource" "conveyance_server_farm" {
  type                      = "Microsoft.Web/serverfarms@2023-12-01"
  schema_validation_enabled = false
  location                  = var.azure_region
  name                      = "${module.app_service_plan.name.abbreviation}-Conveyance${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id = azurerm_resource_group.conveyance.id
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

resource "azurerm_storage_account" "conveyance_function" {
  name                     = "${module.storage_account.name.abbreviation}conveyf${var.resource_name_suffix}${var.azure_environment}${module.azure_regions.region.region_short}"
  resource_group_name      = azurerm_resource_group.conveyance.name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.conveyance_tags
}

resource "azurerm_storage_container" "conveyance_deployment_package" {
  name                  = "deploymentpackage"
  storage_account_name  = azurerm_storage_account.conveyance_function.name
  container_access_type = "private"
}

locals {
    conveyance-BlobStorageAndContainer = "${azurerm_storage_account.conveyance_function.primary_blob_endpoint}deploymentpackage"
}

variable "conveyance_max_instance_count" {
  type = number
  default = 100
  description = "The maximum number of instances that the Conveyance function app can scale to."
}

variable "conveyance_instance_memory" {
  type = number
  default = 2048
  description = "The maximum amount of memory that the Conveyance function app can use."
}

resource "azapi_resource" "conveyance_function_app" {
  type                      = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location                  = var.azure_region
  name                      = "${module.function_app.name.abbreviation}-Conveyance${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id = azurerm_resource_group.conveyance.id
  body = jsonencode({
    kind = "functionapp,linux",
    identity = {
      type: "SystemAssigned"
    }
    properties = {
      serverFarmId = azapi_resource.conveyance_server_farm.id,
        functionAppConfig = {
          deployment = {
            storage = {
              type = "blobContainer",
              value = local.conveyance-BlobStorageAndContainer,
              authentication = {
                type = "SystemAssignedIdentity"
              }
            }
          },
          scaleAndConcurrency = {
            maximumInstanceCount = var.conveyance_max_instance_count,
            instanceMemoryMB = var.conveyance_instance_memory
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
              value = azurerm_storage_account.conveyance_function.name
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
    azapi_resource.conveyance_server_farm,
    azurerm_application_insights.app_insights,
    azurerm_storage_account.conveyance_function,
    azurerm_storage_container.conveyance_deployment_package
  ]
}

data "azurerm_linux_function_app" "conveyance_wrapper" {
    name = azapi_resource.conveyance_function_app.name
    resource_group_name = azurerm_resource_group.conveyance.name
}

resource "azurerm_role_assignment" "conveyance_function_storage_acccount" {
  scope = azurerm_storage_account.conveyance_function.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id = data.azurerm_linux_function_app.conveyance_wrapper.identity.0.principal_id
}

# Role Assignment: Key Vault Secrets User (func-lookupapi)
resource "azurerm_role_assignment" "conveyance_key_vault_secrets_user" {
  scope                = azurerm_key_vault.remanufacturing.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_linux_function_app.conveyance_wrapper.identity.*.principal_id[0]
}

# Role Assignment: App Configuration Data Owner (func-lookupapi)
resource "azurerm_role_assignment" "conveyance_app_configuration_data_owner" {
  scope                = azurerm_app_configuration.remanufacturing.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_linux_function_app.conveyance_wrapper.identity.*.principal_id[0]
}

resource "azurerm_role_assignment" "conveyance_storage_blob_contributor" {
  scope                = azurerm_storage_account.conveyance.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_linux_function_app.conveyance_wrapper.identity.*.principal_id[0]
}