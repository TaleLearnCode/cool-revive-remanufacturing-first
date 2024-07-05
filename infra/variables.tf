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