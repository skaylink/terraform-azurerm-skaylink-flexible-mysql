# A Terraform module to create a subset of cloud components
# Copyright (C) 2022 Skaylink GmbH

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# For questions and contributions please contact info@iq3cloud.com

terraform {
  required_version = ">= 1.3"
  required_providers {
    random = {
      version = "> 3.4"
      source  = "hashicorp/random"
    }
    azurerm = {
      version = "> 3.30"
      source  = "hashicorp/azurerm"
    }
  }
}

locals {
  server_name = "${var.usecase}-${var.environment}-f-mysql"
}

resource "random_password" "password" {
  length  = 24
  special = true
}

#tfsec:ignore:azure-keyvault-ensure-secret-expiry
resource "azurerm_key_vault_secret" "password" {
  name         = "${local.server_name}-password"
  value        = random_password.password.result
  key_vault_id = data.azurerm_key_vault.kv.id
  content_type = "password"
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = local.server_name
  resource_group_name    = data.azurerm_resource_group.rg.name
  location               = data.azurerm_resource_group.rg.location
  administrator_login    = "psqladmin"
  administrator_password = random_password.password.result
  zone                   = "1"
  backup_retention_days  = var.backup_retention_days
  version                = var.engine_version == null ? null : var.engine_version
  sku_name               = var.sku
  delegated_subnet_id    = var.delegated_subnet_name == null ? null : data.azurerm_subnet.subnet[0].id
  private_dns_zone_id    = var.delegated_subnet_name == null ? null : resource.azurerm_private_dns_zone.dns_zone[0].id

  storage {
    auto_grow_enabled = true
    iops              = var.iops
    size_gb           = var.size_gb
  }

  dynamic "high_availability" {
    for_each = var.high_availability == true ? [true] : []
    content {
      mode = var.zone_redundant == true ? "ZoneRedundant" : "SameZone"
    }
  }
}

# based on https://errorsfixing.com/terraform-azure-mysql-gtid_mode-on-error/
resource "azurerm_mysql_configuration" "time_zone" {
  count               = var.gtid_enabled == true ? 1 : 0
  name                = "time_zone"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  value               = "+00:00"
  depends_on = [
    azurerm_mysql_flexible_server.mysql
  ]
}

# based on https://errorsfixing.com/terraform-azure-mysql-gtid_mode-on-error/
resource "azurerm_mysql_configuration" "enforce_gtid_consistency" {
  count               = var.gtid_enabled == true ? 1 : 0
  name                = "enforce_gtid_consistency"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  value               = "ON"
  depends_on = [
    azurerm_mysql_configuration.time_zone
  ]
}

# based on https://errorsfixing.com/terraform-azure-mysql-gtid_mode-on-error/
resource "azurerm_mysql_configuration" "gtid_mode_OFF_permissive" {
  count               = var.gtid_enabled == true ? 1 : 0
  name                = "gtid_mode"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  value               = "OFF_PERMISSIVE"
  depends_on = [
    azurerm_mysql_configuration.enforce_gtid_consistency,
  ]
}

# based on https://errorsfixing.com/terraform-azure-mysql-gtid_mode-on-error/
resource "azurerm_mysql_configuration" "gtid_mode_ON_Permissive" {
  count               = var.gtid_enabled == true ? 1 : 0
  name                = "gtid_mode"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  value               = "ON_PERMISSIVE"
  depends_on = [
    azurerm_mysql_configuration.gtid_mode_OFF_permissive
  ]
}

# based on https://errorsfixing.com/terraform-azure-mysql-gtid_mode-on-error/
resource "azurerm_mysql_configuration" "gtid_mode_ON" {
  count               = var.gtid_enabled == true ? 1 : 0
  name                = "gtid_mode"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  value               = "ON"
  depends_on = [
    azurerm_mysql_configuration.gtid_mode_ON_Permissive
  ]
}

resource "azurerm_mysql_flexible_database" "databases" {
  for_each            = toset(var.databases)
  name                = each.value
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
  depends_on          = [azurerm_mysql_flexible_server.mysql]
}

resource "azurerm_private_dns_zone" "dns_zone" {
  count               = var.delegated_subnet_name != null ? 1 : 0
  name                = "${var.private_dns_zone_name}.mysql.database.azure.com"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count                 = var.delegated_subnet_name != null ? 1 : 0
  name                  = "vnet-link"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone[0].name
  virtual_network_id    = data.azurerm_virtual_network.vnet[0].id
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_external_access_mysql" {
  for_each            = var.allow_external_access_mysql != null ? var.allow_external_access_mysql : {}
  name                = each.key
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  start_ip_address    = each.value.start
  end_ip_address      = each.value.end
  depends_on          = [azurerm_mysql_flexible_server.mysql]
}

resource "azurerm_mysql_flexible_server_configuration" "mysql_parameters" {
  for_each            = var.mysql_parameters != null ? var.mysql_parameters : {}
  name                = each.key
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  value               = each.value
  depends_on          = [azurerm_mysql_flexible_server.mysql]
}
