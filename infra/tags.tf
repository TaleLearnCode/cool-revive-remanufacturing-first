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