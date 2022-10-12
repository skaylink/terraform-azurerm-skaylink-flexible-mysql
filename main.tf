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

locals {
  server_name = "${var.usecase}-${var.environment}-f-mysql"
}

resource "random_password" "password" {
  length  = 24
  special = true
}

resource "azurerm_key_vault_secret" "password" {
  name         = "${local.server_name}-password"
  value        = random_password.password.result
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = local.server_name
  resource_group_name    = data.azurerm_resource_group.rg.name
  location               = data.azurerm_resource_group.rg.name
  administrator_login    = "psqladmin"
  administrator_password = random_password.password.result
  zone                   = "1"
  backup_retention_days  = var.backup_retention_days
  sku_name               = var.sku

  storage {
    auto_grow_enabled = true
    iops              = var.iops
    size_gb           = var.size_gb
  }

  high_availability {
    mode = var.zone_redundant == true ? "ZoneRedundant" : "SameZone"
  }
}

resource "azurerm_mysql_flexible_database" "databases" {
  for_each            = toset(var.databases)
  name                = each.value
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}
