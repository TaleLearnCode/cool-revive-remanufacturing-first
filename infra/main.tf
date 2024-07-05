# #############################################################################
# Provider Configuration
# #############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

# #############################################################################
# Common Variables
# #############################################################################

variable "azure_region" {
	type        = string
  default     = "eastus2"
	description = "Location of the resource group."
}

variable "azure_environment" {
	type        = string
  default     = "gh"
	description = "The environment component of an Azure resource name."
}

variable "resource_name_suffix" {
  type        = string
  default     = "756"
  description = "The suffix to append to the resource names."
}

variable "resource_group_name" {
  type        = string
  default     = "rg-CoolRevive-gh-use2"
  description = "The name of the resource group."
}

variable "company_name" {
  type        = string
  default     = "CoolRevive"
  description = "The name of the company."
}

variable "system_name" {
  type        = string
  default     = "Remanufacturing"
  description = "The name of the system."
}

# #############################################################################
#                             Tags
# #############################################################################

variable "tag_product" {
  type        = string
  default     = "Remanufacturing"
  description = "The product or service that the resources are being created for."
}

variable "tag_cost_center" {
  type        = string
  default     = "Remanufacturing"
  description = "Accounting cost center associated with the resource."
}

variable "tag_criticality" {
  type        = string
  default     = "Medium"
  description = "The business impact of the resource or supported workload. Valid values are Low, Medium, High, Business Unit Critical, Mission Critical."
}

variable "tag_disaster_recovery" {
  type        = string
  default     = "Dev"
  description = "Business criticality of the application, workload, or service. Valid values are Mission Critical, Critical, Essential, Dev."
}

locals {
  tags = {
    Product     = var.tag_product
    Criticality = var.tag_criticality
    CostCenter  = "${var.tag_cost_center}-${var.azure_environment}"
    DR          = var.tag_disaster_recovery
    Env         = var.azure_environment
  }
}

# #############################################################################
# Referenced Resoruces
# #############################################################################

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# #############################################################################
# Modules
# #############################################################################

module "azure_regions" {
  source       = "git::https://github.com/TaleLearnCode/terraform-azure-regions.git"
  azure_region = var.azure_region
}

module "resource_group" {
  source        = "git::https://github.com/TaleLearnCode/azure-resource-types.git"
  resource_type = "resource-group"
}

module "api_management" {
  source        = "git::https://github.com/TaleLearnCode/azure-resource-types.git"
  resource_type = "api-management-service-instance"
}

module "service_bus_namespace" {
  source        = "git::https://github.com/TaleLearnCode/azure-resource-types.git"
  resource_type = "service-bus-namespace"
}

module "cosmos_account" {
  source        = "git::https://github.com/TaleLearnCode/azure-resource-types.git"
  resource_type = "azure-cosmos-db-for-nosql-account"
}

module "log_analytics_workspace" {
  source = "git::git@ssh.dev.azure.com:v3/JasperEnginesTransmissions/JETDEV/TerraformModule_AzureResourceTypes"
  resource_type = "log-analytics-workspace"
}

module "application_insights" {
  source = "git::git@ssh.dev.azure.com:v3/JasperEnginesTransmissions/JETDEV/TerraformModule_AzureResourceTypes"
  resource_type = "application-insights"
}

module "event_grid_topic" {
  source = "git::https://github.com/TaleLearnCode/azure-resource-types.git"
  resource_type = "event-grid-topic"
}

module "service_bus_topic" {
  source = "git::https://github.com/TaleLearnCode/azure-resource-types.git"
  resource_type = "service-bus-topic"
}

module "service_bus_topic_subscription" {
  source = "git::https://github.com/TaleLearnCode/azure-resource-types.git"
  resource_type = "service-bus-topic-subscription"
}
module "app_service_plan" {
  source = "git::https://github.com/TaleLearnCode/azure-resource-types.git"
  resource_type = "app-service-plan"
}

module "function_app" {
  source = "git::https://github.com/TaleLearnCode/azure-resource-types.git"
  resource_type = "function-app"
}

module "storage_account" {
  source        = "git::https://github.com/TaleLearnCode/azure-resource-types.git"
  resource_type = "storage-account"
}