terraform {
  required_version = ">=1.0"

  required_providers {
    # Azure Resource Management:
    # Used to configure infrastructure in Microsoft Azure using the Azure Resource Manager API
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    # Supports the use of randomness within Terraform configurations.
    # This is a logical provider, which means that it works entirely within Terraform logic,
    # and does not interact with any other services.
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Credentials ( better as env variables )
  subscription_id   = "**************************************"
  tenant_id         = "**************************************"
  client_id         = "**************************************"
  client_secret     = "**************************************"
}