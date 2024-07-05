# #############################################################################
# API Management
# #############################################################################

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "apim_publisher_name" {
  type        = string
  default     = "Nebraska.Code"
  description = "The name of the publisher of the API Management instance."
}

variable "apim_publisher_email" {
  type        = string
  default     = "chad.green@chadgreen.com"
  description = "The email address of the publisher of the API Management instance."
}

variable "apim_sku_name" {
  type        = string
  default     = "Developer_1"
  description = "The SKU of the API Management instance."
}

# -----------------------------------------------------------------------------
# API Management Service Instance
# -----------------------------------------------------------------------------

resource "azurerm_api_management" "apim" {
  name                = lower("${module.api_management.name.abbreviation}-${var.company_name}-${var.azure_environment}-${module.azure_regions.region.region_short}")
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku_name            = var.apim_sku_name
}