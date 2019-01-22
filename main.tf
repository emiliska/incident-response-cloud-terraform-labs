# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "incident_response_group" {
    name     = "incidentResponseLab"
    location = "northcentralus"

    tags {
        environment = "IRLab01"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "incident_response_network" {
    name                = "Network01"
    address_space       = ["10.0.0.0/16"]
    location            = "northcentralus"
    resource_group_name = "${azurerm_resource_group.incident_response_group.name}"

    tags {
        environment = "IRLab01"
    }
}

# Create subnet
resource "azurerm_subnet" "incident_response_subnet_01" {
    name                 = "SUBNET01"
    resource_group_name  = "${azurerm_resource_group.incident_response_group.name}"
    virtual_network_name = "${azurerm_virtual_network.incident_response_network.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "incident_response_public_ip" {
    name                         = "Public IP 01"
    location                     = "northcentralus"
    resource_group_name          = "${azurerm_resource_group.incident_response_group.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "IRLab01"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "incident_response_nsg_01" {
    name                = "Network Security Group 01"
    location            = "northcentralus"
    resource_group_name = "${azurerm_resource_group.incident_response_group.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "IRLab01"
    }
}

# Create network interface
resource "azurerm_network_interface" "incident_response_nic_01" {
    name                      = "NIC01"
    location                  = "northcentralus"
    resource_group_name       = "${azurerm_resource_group.incident_response_group.name}"
    network_security_group_id = "${azurerm_network_security_group.incident_response_nsg_01.id}"

    ip_configuration {
        name                          = "myNicConfigurationA"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.incident_response_public_ip.id}"
    }

    tags {
        environment = "IRLab01"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.incident_response_group.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "incident_response_storage_account_01" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.incident_response_group.name}"
    location                    = "northcentralus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "IRLab01"
    }
}

# Create virtual machine DETMNG001
resource "azurerm_virtual_machine" "myterraformvmDETMNG001" {
    name                  = "DETMNG001"
    location              = "northcentralus"
    resource_group_name   = "${azurerm_resource_group.incident_response_group.name}"
    network_interface_ids = ["${azurerm_network_interface.incident_response_nic_01.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "12.04.3-LTS"
        version   = "12.04.201401270"
    }

    os_profile {
        computer_name  = "DETMNG002"
        admin_username = "azureuser"
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.incident_response_storage_account_01.primary_blob_endpoint}"
    }

    tags {
        environment = "IRLab01"
    }
}


# Create virtual machine DETMNG002
resource "azurerm_virtual_machine" "myterraformvmDETMNG002" {
    name                  = "DETMNG002"
    location              = "northcentralus"
    resource_group_name   = "${azurerm_resource_group.incident_response_group.name}"
    network_interface_ids = ["${azurerm_network_interface.incident_response_nic_01.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2012-Datacenter"
        version   = "latest"
    }

    os_profile {
        computer_name  = "DETMNG002"
        admin_username = "azureuser"
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.incident_response_storage_account_01.primary_blob_endpoint}"
    }

    tags {
        environment = "IRLab01"
    }
}

# Create virtual machine XERUS01
resource "azurerm_virtual_machine" "myterraformvmXERUS01" {
    name                  = "XERUS01"
    location              = "northcentralus"
    resource_group_name   = "${azurerm_resource_group.incident_response_group.name}"
    network_interface_ids = ["${azurerm_network_interface.incident_response_nic_01.id}"]
    vm_size               = "Standard_DS3_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "XERUS01"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3Nz{snip}hwhqT9h"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.incident_response_storage_account_01.primary_blob_endpoint}"
    }

    tags {
        environment = "IRLab01"
    }
}

# Create virtual machine XERUS02
resource "azurerm_virtual_machine" "myterraformvmXERUS02" {
    name                  = "XERUS02"
    location              = "northcentralus"
    resource_group_name   = "${azurerm_resource_group.incident_response_group.name}"
    network_interface_ids = ["${azurerm_network_interface.incident_response_nic_01.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "XERUS02"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3Nz{snip}hwhqT9h"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.incident_response_storage_account_01.primary_blob_endpoint}"
    }

    tags {
        environment = "IRLab01"
    }
}

# Create virtual machine WIN2K16A
resource "azurerm_virtual_machine" "myterraformvmWIN2K16A" {
    name                  = "WIN2K16A"
    location              = "northcentralus"
    resource_group_name   = "${azurerm_resource_group.incident_response_group.name}"
    network_interface_ids = ["${azurerm_network_interface.incident_response_nic_01.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }

    os_profile {
        computer_name  = "WIN2K16A"
        admin_username = "azureuser"
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.incident_response_storage_account_01.primary_blob_endpoint}"
    }

    tags {
        environment = "IRLab01"
    }
}

# Create virtual machine WIN2K16B
resource "azurerm_virtual_machine" "myterraformvmWIN2K16B" {
    name                  = "WIN2K16B"
    location              = "northcentralus"
    resource_group_name   = "${azurerm_resource_group.incident_response_group.name}"
    network_interface_ids = ["${azurerm_network_interface.incident_response_nic_01.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }

    os_profile {
        computer_name  = "WIN2K16B"
        admin_username = "azureuser"
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.incident_response_storage_account_01.primary_blob_endpoint}"
    }

    tags {
        environment = "IRLab01"
    }
}