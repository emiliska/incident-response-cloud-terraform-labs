# Create virtual network
resource "azurerm_virtual_network" "networks" {
    name                = "IRNET01"
    address_space       = ["10.0.0.0/16"]
    location            = "northcentralus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags {
        environment = "IRLAB"
    }

}

# Create subnet
resource "azurerm_subnet" "subnets" {
    name                 = "Subnet_IRLAB01"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"

    depends_on = ["${azurerm_virtual_network.networks}"]
}

# Create public IPs
resource "azurerm_public_ip" "publicips" {
    name                         = "PublicIP_IRLAB01"
    location                     = "northcentralus"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "IRLAB"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "netsecgroup" {
    name                = "NetworkSecurityGroup_IRLAB01"
    location            = "northcentralus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

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

    depends_on = ["${azurerm_virtual_network.networks}"]

    tags {
        environment = "IRLAB"
    }
}

# Create network interface
resource "azurerm_network_interface" "nics" {
    name                      = "NIC001"
    location                  = "northcentralus"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "IP001"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "IRLAB"
    }
}