terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.45.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ---------- Resource Group ----------
resource "azurerm_resource_group" "rg" {
  name     = "workforce-rg"
  location = "uksouth"
}

# ---------- Virtual Network ----------
resource "azurerm_virtual_network" "vnet" {
  name                = "workforce-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["15.0.0.0/16"]
}

# ---------- Subnets ----------
resource "azurerm_subnet" "bastion_subnet1" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["15.0.1.0/24"]
}
resource "azurerm_subnet" "app_subnet" {
  name                 = "workforce-app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["15.0.2.0/24"]
}
resource "azurerm_subnet" "db_subnet" {
  name                 = "workforce-db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["15.0.3.0/24"] # Correction yahan hai
}

# ---------- NSGs ----------
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_network_security_group" "db_nsg" {
  name                = "db-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# ---------- NSG Rules for App ----------
resource "azurerm_network_security_rule" "app_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.app_nsg.name
}
resource "azurerm_network_security_rule" "app_https" {
  name                        = "allow-https"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.app_nsg.name
}

# # ---------- NSG Rules for DB ----------
# resource "azurerm_network_security_rule" "db_sql" {
#   name                        = "allow-sql-from-app"
#   priority                    = 100
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "1433"
#   source_address_prefix       = "15.0.1.0/24" # Yahan app subnet ka range aayega
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.db_nsg.name
# }

# # Optional: explicit deny rule for extra security (not strictly needed, since Azure default rules deny all)
# resource "azurerm_network_security_rule" "db_deny_internet" {
#   name                        = "deny-internet"
#   priority                    = 200
#   direction                   = "Inbound"
#   access                      = "Deny"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "Internet"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.db_nsg.name
# }

# # ---------- Associate NSGs with Subnets ----------
# resource "azurerm_subnet_network_security_group_association" "app_nsg_assoc" {
#   subnet_id                 = azurerm_subnet.app_subnet.id
#   network_security_group_id = azurerm_network_security_group.app_nsg.id
# }
# resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc" {
#   subnet_id                 = azurerm_subnet.db_subnet.id
#   network_security_group_id = azurerm_network_security_group.db_nsg.id
# }

