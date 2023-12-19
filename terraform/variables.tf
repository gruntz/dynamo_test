variable "resource_group_location" {
  default     = "eastus" # East US
  description = "Location of the resource group."
}

variable "prefix" {
  type        = string
  default     = "dynamo"
  description = "Prefix of the resource name"
}