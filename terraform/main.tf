# Container for all resources in the project:
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "${var.prefix}-rg"
}

# Create virtual network: ( Same for both VMs)
resource "azurerm_virtual_network" "dynamo_terraform_network" {
  name                = "${var.prefix}-common-virtul-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet: ( Same for both VMs )
resource "azurerm_subnet" "dynamo_terraform_subnet" {
  name                 = "${var.prefix}-common-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dynamo_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

#
# Create public IPs:
#
resource "azurerm_public_ip" "dynamo_terraform_public_ip_server" {
  name                = "${var.prefix}-Server-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "dynamo_terraform_public_ip_worker" {
  name                = "${var.prefix}-Worker-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

#
# Create Network Security Group and rules
#
resource "azurerm_network_security_group" "dynamo_terraform_network_security_group_server" {
  name                = "${var.prefix}-Server-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP-Security-Rule"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "WEB-Security-Rule"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "dynamo_terraform_network_security_group_worker" {
  name                = "${var.prefix}-Worker-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP-Security-Rule"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#
# Create network interfaces:
#
resource "azurerm_network_interface" "dynamo_terraform_network_interface_server" {
  name                = "${var.prefix}-Server-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "dynamo_nic_configuration"
    subnet_id                     = azurerm_subnet.dynamo_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dynamo_terraform_public_ip_server.id
  }
}

resource "azurerm_network_interface" "dynamo_terraform_network_interface_worker" {
  name                = "${var.prefix}-Worker-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "dynamo_nic_configuration"
    subnet_id                     = azurerm_subnet.dynamo_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dynamo_terraform_public_ip_worker.id
  }
}

#
# Connect the security group to the network interface:
#
resource "azurerm_network_interface_security_group_association" "add_sg_to_server_nic" {
  network_interface_id      = azurerm_network_interface.dynamo_terraform_network_interface_server.id
  network_security_group_id = azurerm_network_security_group.dynamo_terraform_network_security_group_server.id
}

resource "azurerm_network_interface_security_group_association" "add_sg_to_worker_nic" {
  network_interface_id      = azurerm_network_interface.dynamo_terraform_network_interface_worker.id
  network_security_group_id = azurerm_network_security_group.dynamo_terraform_network_security_group_worker.id
}

#
# Create storage account for boot diagnostics:
#
resource "azurerm_storage_account" "dynamo_storage_account_server" {
  name                     = "diagsrv${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "dynamo_storage_account_worker" {
  name                     = "diagwrk${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#
# Create virtual machine:
#
resource "azurerm_windows_virtual_machine" "dyanmo_server_vm" {
  name                  = "${var.prefix}-Server"
  admin_username        = "azureuser"
  admin_password        = "Some.Pass" # random_password.password.result
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.dynamo_terraform_network_interface_server.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "${var.prefix}-Server-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.dynamo_storage_account_server.primary_blob_endpoint
  }
}

resource "azurerm_windows_virtual_machine" "dyanmo_worker_vm" {
  name                  = "${var.prefix}-Worker"
  admin_username        = "azureuser"
  admin_password        = "Some.Pass" # random_password.password.result
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.dynamo_terraform_network_interface_worker.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "${var.prefix}-Worker-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.dynamo_storage_account_worker.primary_blob_endpoint
  }
}

# Install IIS web server AND .NET
resource "azurerm_virtual_machine_extension" "install_server_apps" {
  name                       = "${var.prefix}-Server-wsi"
  virtual_machine_id         = azurerm_windows_virtual_machine.dyanmo_server_vm.id # To which VM to install
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings                   = <<EOF
    {
      "commandToExecute": "powershell -NoProfile -ExecutionPolicy unrestricted -Command \"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; &([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://dot.net/v1/dotnet-install.ps1'))) -Runtime dotnet -Channel 3.1 -InstallDir 'C:\\Program Files\\dotnet' \" && powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"

    }
  EOF

  #"commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"

  #"commandToExecute": "powershell -NoProfile -ExecutionPolicy unrestricted -Command \"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; &([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://dot.net/v1/dotnet-install.ps1'))) -Runtime dotnet -Channel 3.1 -InstallDir 'C:\\Program Files\\dotnet' \""

}

resource "azurerm_virtual_machine_extension" "install_worker_apps" {
  name                       = "${var.prefix}-Worker-wsi"
  virtual_machine_id         = azurerm_windows_virtual_machine.dyanmo_worker_vm.id # To which VM to install
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings                   = <<EOF
    {
      "commandToExecute": "powershell -NoProfile -ExecutionPolicy unrestricted -Command \"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; &([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://dot.net/v1/dotnet-install.ps1'))) -Runtime dotnet -Channel 3.1 -InstallDir 'C:\\Program Files\\dotnet' \" "

    }
  EOF
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }
  byte_length = 8
}

resource "random_password" "password" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

# Adds random postfix after the prefix ( dynano )
# Used like: "${random_pet.prefix.id}-rg", which will return: "dynamo--chigger-rg" 
# resource "random_pet" "prefix" {
#   prefix = var.prefix
#   length = 1
# }