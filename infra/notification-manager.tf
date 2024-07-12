# #############################################################################
# Notification Manager
# #############################################################################

# ------------------------------------------------------------------------------
#                             Tags
# ------------------------------------------------------------------------------

variable "notification_tag_product" {
  type        = string
  default     = "Notification Manager"
  description = "The product or service that the resources are being created for."
}

variable "notification_tag_cost_center" {
  type        = string
  default     = "Core"
  description = "Accounting cost center associated with the resource."
}

variable "notification_tag_criticality" {
  type        = string
  default     = "High"
  description = "The business impact of the resource or supported workload. Valid values are Low, Medium, High, Business Unit Critical, Mission Critical."
}

variable "notification_tag_disaster_recovery" {
  type        = string
  default     = "Dev"
  description = "Business criticality of the application, workload, or service. Valid values are Mission Critical, Critical, Essential, Dev."
}

locals {
  notification_tags = {
    Product     = var.notification_tag_product
    Criticality = var.notification_tag_criticality
    CostCenter  = "${var.notification_tag_cost_center}-${var.azure_environment}"
    DR          = var.notification_tag_disaster_recovery
    Env         = var.azure_environment
  }
}



variable "acs_data_location" {
  type        = string
  default     = "United States"
  description = "The location of the data for the communication service."
}


resource "azurerm_resource_group" "notification_manager" {
  name     = "${module.resource_group.name.abbreviation}-CoolRevive_NotificationManager-${var.azure_environment}-${module.azure_regions.region.region_short}"
  location = var.azure_region
  tags     = local.notification_tags
}

resource "azurerm_email_communication_service" "notification_manager" {
  name                = "email-NotificationManager${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  resource_group_name = azurerm_resource_group.notification_manager.name
  data_location       = var.acs_data_location
  tags                = local.notification_tags
}

resource "azurerm_email_communication_service_domain" "notification_manager" {
  name              = "AzureManagedDomain"
  email_service_id  = azurerm_email_communication_service.notification_manager.id
  domain_management = "AzureManaged"
}

resource "azurerm_communication_service" "notification_manager" {
  name                = "${module.communication_services.name.abbreviation}-NotificationManager-${var.azure_environment}-${module.azure_regions.region.region_short}"
  resource_group_name = azurerm_resource_group.notification_manager.name
  data_location       = var.acs_data_location
  tags                = local.notification_tags
}

resource "azurerm_key_vault_secret" "communication_service_connection_string" {
  name         = "NotificationManager-CommunicationService-ConnectionString"
  value        = azurerm_communication_service.notification_manager.primary_connection_string
  key_vault_id = azurerm_key_vault.remanufacturing.id
}

resource "azurerm_app_configuration_key" "communication_services_connection_string" {
  configuration_store_id = azurerm_app_configuration.remanufacturing.id
  key                    = "NotificationManager:CommunicationService:ConnectionString"
  type                   = "vault"
  label                  = var.azure_environment
  vault_key_reference    = azurerm_key_vault_secret.communication_service_connection_string.versionless_id
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "azurerm_servicebus_subscription" "notifiy_next_core_in_transit" {
  name               = "${module.service_bus_topic_subscription.name.abbreviation}-NotifyNextCoreInTransit-${var.azure_environment}-${module.azure_regions.region.region_short}"
  topic_id           = azurerm_servicebus_topic.next_core_in_transit.id
  max_delivery_count = 1
  depends_on = [ 
    azurerm_servicebus_topic.next_core_in_transit
   ]
}

resource "azurerm_app_configuration_key" "notifiy_next_core_in_transit_subscription_name" {
  configuration_store_id = azurerm_app_configuration.remanufacturing.id
  key                    = "ServiceBus:Topics:NextCoreInTransit:Subscriptions:NotifyNextCoreInTransit"
  label                  = var.azure_environment
  value                  = azurerm_servicebus_subscription.notifiy_next_core_in_transit.name
}



resource "azurerm_storage_account" "notification_manager" {
  name                     = "${module.storage_account.name.abbreviation}notifynmg${var.resource_name_suffix}${var.azure_environment}${module.azure_regions.region.region_short}"
  resource_group_name      = azurerm_resource_group.notification_manager.name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.notification_tags
}

resource "azurerm_storage_table" "contact_list" {
  name = "ContactList"
  storage_account_name = azurerm_storage_account.notification_manager.name
}

resource "azurerm_storage_table_entity" "example" {
  storage_table_id = azurerm_storage_table.contact_list.id

  partition_key = "pod123"
  row_key       = "CoreInTransit"

  entity = {
    EmailAddress = "chadgreen@chadgreen.com"
  }
}






resource "azapi_resource" "notification_manager_server_farm" {
  type                      = "Microsoft.Web/serverfarms@2023-12-01"
  schema_validation_enabled = false
  location                  = var.azure_region
  name                      = "${module.app_service_plan.name.abbreviation}-NotificationManager${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id = azurerm_resource_group.notification_manager.id
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

resource "azurerm_storage_account" "notification_manager_function" {
  name                     = "${module.storage_account.name.abbreviation}notifynmgf${var.resource_name_suffix}${var.azure_environment}${module.azure_regions.region.region_short}"
  resource_group_name      = azurerm_resource_group.notification_manager.name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.notification_tags
}

resource "azurerm_storage_container" "notification_manager_deployment_package" {
  name                  = "deploymentpackage"
  storage_account_name  = azurerm_storage_account.notification_manager_function.name
  container_access_type = "private"
}

locals {
    blobStorageAndContainer = "${azurerm_storage_account.notification_manager_function.primary_blob_endpoint}deploymentpackage"
}

variable "notification_manager_max_instance_count" {
  type = number
  default = 100
  description = "The maximum number of instances that the Notification Manager function app can scale to."
}

variable "notification_manager_instance_memory" {
  type = number
  default = 2048
  description = "The maximum amount of memory that the Notification Manager function app can use."
}

resource "azapi_resource" "notification_managre_function_app" {
  type                      = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location                  = var.azure_region
  name                      = "${module.function_app.name.abbreviation}-NotificationManager${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id = azurerm_resource_group.notification_manager.id
  body = jsonencode({
    kind = "functionapp,linux",
    identity = {
      type: "SystemAssigned"
    }
    properties = {
      serverFarmId = azapi_resource.notification_manager_server_farm.id,
        functionAppConfig = {
          deployment = {
            storage = {
              type = "blobContainer",
              value = local.blobStorageAndContainer,
              authentication = {
                type = "SystemAssignedIdentity"
              }
            }
          },
          scaleAndConcurrency = {
            maximumInstanceCount = var.notification_manager_max_instance_count,
            instanceMemoryMB = var.notification_manager_instance_memory
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
              value = azurerm_storage_account.notification_manager_function.name
            },
            {
              name = "APPLICATIONINSIGHTS_CONNECTION_STRING",
              value = azurerm_application_insights.app_insights.connection_string
            },
            {
              name = "CommunicationServicesConnectionString",
              value = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.communication_services_connection_string.key}; Label=${var.azure_environment})"
            },
            {
              name = "ServiceBusConnectionString",
              value = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.service_bus_connection_string.key}; Label=${var.azure_environment})"
            },
            {
              name = "NextCoreInTransit_TopicName",
              value = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.notify_next_core_in_transit_topic_name.key}; Label=${var.azure_environment})"
            },
            {
              name = "NextCoreInTransit_Subscription",
              value = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.notifiy_next_core_in_transit_subscription_name.key}; Label=${var.azure_environment})"
            }
          ]
        }
      }
  })
  depends_on = [
    azapi_resource.notification_manager_server_farm,
    azurerm_application_insights.app_insights,
    azurerm_storage_account.notification_manager_function,
    azurerm_storage_container.notification_manager_deployment_package
  ]
}

data "azurerm_linux_function_app" "notification_manager_wrapper" {
    name = azapi_resource.notification_managre_function_app.name
    resource_group_name = azurerm_resource_group.notification_manager.name
}

resource "azurerm_role_assignment" "notification_manager_function_storage_acccount" {
  scope = azurerm_storage_account.notification_manager_function.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id = data.azurerm_linux_function_app.notification_manager_wrapper.identity.0.principal_id
}

# Role Assignment: Key Vault Secrets User (func-lookupapi)
resource "azurerm_role_assignment" "notification_manager_key_vault_secrets_user" {
  scope                = azurerm_key_vault.remanufacturing.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_linux_function_app.notification_manager_wrapper.identity.*.principal_id[0]
}

# Role Assignment: App Configuration Data Owner (func-lookupapi)
resource "azurerm_role_assignment" "notification_manager_app_configuration_data_owner" {
  scope                = azurerm_app_configuration.remanufacturing.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_linux_function_app.notification_manager_wrapper.identity.*.principal_id[0]
}





resource "azurerm_cosmosdb_sql_database" "inventory" {
  name                = "inventory"
  resource_group_name = azurerm_cosmosdb_account.cosmos.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  throughput          = 400
}

resource "azurerm_cosmosdb_sql_container" "inventory" {
  name                  = "inventory"
  resource_group_name   = data.azurerm_cosmosdb_account.cosmos.resource_group_name
  account_name          = data.azurerm_cosmosdb_account.cosmos.name
  database_name         = azurerm_cosmosdb_sql_database.inventory.name
  partition_key_paths = [ "podId" ]
  throughput            = 400
}

resource "azurerm_cosmosdb_sql_container" "inventory_event_source" {
  name                  = "inventory-eventsource"
  resource_group_name   = data.azurerm_cosmosdb_account.cosmos.resource_group_name
  account_name          = data.azurerm_cosmosdb_account.cosmos.name
  database_name         = azurerm_cosmosdb_sql_database.inventory.name
  partition_key_paths = [ "podId" ]
  throughput            = 400
}