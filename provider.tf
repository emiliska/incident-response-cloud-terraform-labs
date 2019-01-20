# declare a provider and provide Azure auth credentials
provider "azurerm" { 
    version = "=1.21.0"
    project = "incident-response-labs-azure"
    credentials = "${file("account.json")}"
}

# Create a resource group
resource "azurerm_resource_group" "IRLAB" {
    name     = "production"
    location = "North Central US"

    tags {
        environment = "IRLAB"
    }
}

