# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "incident_response" {
    name     = "lab01"
    location = "North Central US"

    tags {
        environment = "IR"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "networks" {
    name                = "net01"
    address_space       = ["10.0.0.0/16"]
    location            = "North Central US"
    resource_group_name = "${azurerm_resource_group.incident_response.name}"

    tags {
        environment = "IR"
    }
}

# Create subnet
resource "azurerm_subnet" "subnets" {
    name                 = "sub01"
    resource_group_name  = "${azurerm_resource_group.incident_response.name}"
    virtual_network_name = "${azurerm_virtual_network.networks.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "public_ips" {
    name                         = "pubip01"
    location                     = "North Central US"
    resource_group_name          = "${azurerm_resource_group.incident_response.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "IR"
    }
}

# Create a firewall

resource "azurerm_firewall" "Firewalls" {
    name                = "firewall01"
    location            = "${azurerm_resource_group.incident_response.location}"
    resource_group_name = "${azurerm_resource_group.incident_response.name}"

    ip_configuration {
        name                 = "configuration"
        subnet_id            = "${azurerm_subnet.subnets.id}"
        public_ip_address_id = "${azurerm_public_ip.public_ips.id}"
    }

    tags {
        environment = "IR"
    }

}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "netsecgroup" {
    name                = "nsg01"
    location            = "North Central US"
    resource_group_name = "${azurerm_resource_group.incident_response.name}"

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
        environment = "IR"
    }
}

# Create network interface
resource "azurerm_network_interface" "nics" {
    name                      = "nic01"
    location                  = "North Central US"
    resource_group_name       = "${azurerm_resource_group.incident_response.name}"
    network_security_group_id = "${azurerm_network_security_group.netsecgroup.id}"

    ip_configuration {
        name                          = "nic_config01"
        subnet_id                     = "${azurerm_subnet.subnets.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.public_ips.id}"
    }

    tags {
        environment = "IR"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.incident_response.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storage" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.incident_response.name}"
    location                    = "North Central US"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "IR"
    }
}

######################
## VIRTUAL MACHINES ##
######################

# Create virtual machine DETENG01
resource "azurerm_virtual_machine" "DETENG01" {
    name                  = "DETENG01"
    location              = "North Central US"
    resource_group_name   = "${azurerm_resource_group.incident_response.name}"
    network_interface_ids = ["${azurerm_network_interface.nics.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "12.04.3-LTS"
        version   = "12.04.201401270"
    }

    os_profile {
        computer_name  = "DETENG01"
        admin_username = "mitchell.hashimoto"
        admin_password = "Hashicorp2012!"
    }

    os_profile_linux_config {
        disable_password_authentication = "false"
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.storage.primary_blob_endpoint}"
    }

    tags {
        environment = "IR"
    }
}

# Create virtual machine AAENG01
resource "azurerm_virtual_machine" "AAENG01" {
    name                  = "AAENG01"
    location              = "North Central US"
    resource_group_name   = "${azurerm_resource_group.incident_response.name}"
    network_interface_ids = ["${azurerm_network_interface.nics.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "12.04.3-LTS"
        version   = "12.04.201401270"
    }

    os_profile {
        computer_name  = "AAENG01"
        admin_username = "armon.dadgar"
        admin_password = "Hashicorp2012!"
    }

    os_profile_linux_config {
        disable_password_authentication = "false"
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.storage.primary_blob_endpoint}"
    }

    tags {
        environment = "IR"
    }
}

# Create virtual machine DETDNS01
resource "azurerm_virtual_machine" "DETDNS01" {
    name                  = "DETDNS01"
    location              = "North Central US"
    resource_group_name   = "${azurerm_resource_group.incident_response.name}"
    network_interface_ids = ["${azurerm_network_interface.nics.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }

    os_profile {
        computer_name  = "DETDNS01"
        admin_username = "admin"
        admin_password = "ZuNdCXCLAc"
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.storage.primary_blob_endpoint}"
    }

    tags {
        environment = "IR"
    }
}

# Create virtual machine AADNS01
resource "azurerm_virtual_machine" "AADNS01" {
    name                  = "AADNS01"
    location              = "North Central US"
    resource_group_name   = "${azurerm_resource_group.incident_response.name}"
    network_interface_ids = ["${azurerm_network_interface.nics.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2012-Datacenter"
        version   = "latest"
    }

    os_profile {
        computer_name  = "AADNS01"
        admin_username = "admin"
        admin_password = "aqL386wjq3wY"
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.storage.primary_blob_endpoint}"
    }

    tags {
        environment = "IR"
    }
}
