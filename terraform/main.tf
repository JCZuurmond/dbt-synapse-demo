terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "synapse" {
  name = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_key_vault" "synapse" {
  name                        = azurerm_resource_group.synapse.name
  location                    = azurerm_resource_group.synapse.location
  resource_group_name         = azurerm_resource_group.synapse.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set"
    ]
  }
}

resource "random_string" "storage_account_name_suffix" {
  keepers = {
    resource_group_name = azurerm_resource_group.synapse.name
  }

  length = 4
  lower  = true
  upper  = false
}

resource "azurerm_storage_account" "synapse" {
  name                     = "${lower(replace(replace(azurerm_resource_group.synapse.name, " ", ""), "-", ""))}${random_string.storage_account_name_suffix.result}"
  resource_group_name      = azurerm_resource_group.synapse.name
  location                 = azurerm_resource_group.synapse.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  name               = "synapse"
  storage_account_id = azurerm_storage_account.synapse.id
}

resource "random_string" "sql_administrator_login_password" {
  keepers = {
    resource_group_name = azurerm_resource_group.synapse.name
  }

  length  = 10
  lower   = true
  upper   = true
  special = true
}

resource "azurerm_key_vault_secret" "synapse" {
  name         = "synapse-sql-administrator-password"
  value        = random_string.sql_administrator_login_password.result
  key_vault_id = azurerm_key_vault.synapse.id
}

resource "azurerm_synapse_workspace" "synapse" {
  name                                 = azurerm_storage_account.synapse.name
  resource_group_name                  = azurerm_resource_group.synapse.name
  location                             = azurerm_resource_group.synapse.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = random_string.sql_administrator_login_password.result

  aad_admin {
    login     = "AzureAD Admin"
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
  }
}

data "http" "client_ip" {
  url = "http://ipv4.icanhazip.com"
}

resource "azurerm_synapse_firewall_rule" "synapse" {
  name                 = "AllowClientIp"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  start_ip_address     = "${chomp(data.http.client_ip.body)}"
  end_ip_address       = "${chomp(data.http.client_ip.body)}"
}
