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

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group you are deploying to"

  # Only allow values that have more than one character, but less than 63.
  validation {
    condition     = length(var.resource_group_name) > 1 && length(var.resource_group_name) <= 63
    error_message = "Resource group names can have a max of 63 characters"
  }
  validation {
    condition     = can(regex("[A-Za-z0-9-_]+", var.resource_group_name))
    error_message = "Invalid value, valid characters are A-Z, a-z, 0-9, hyphens and underscores"
  }
}

variable "usecase" {
  type        = string
  description = "The use case of the resource"

  validation {
    condition     = length(var.usecase) > 1 && length(var.usecase) <= 50
    error_message = "use case name cannot exceed 50 characters"
  }

  validation {
    condition     = can(regex("[A-Za-z0-9-]+", var.usecase))
    error_message = "Invalid value, valid characters are A-Z, a-z, 0-9 and hyphens"
  }
}

variable "environment" {
  type        = string
  description = "The environment we will deploy resources in, for example: dev, test, qa, prd"

  # Only allow values that have more than one character, but less than three.
  validation {
    condition     = length(var.environment) > 1 && length(var.environment) <= 5
    error_message = "Value can't exceed 5 characters"
  }

  # Only allow alphanumeric characters, 1-9 and underscores.
  validation {
    condition     = can(regex("[A-Za-z0-9]+", var.environment))
    error_message = "Invalid value, valid characters are A-Z, a-z and 0-9"
  }
}

variable "key_vault_name" {
  type        = string
  description = "Key vault to store secrets in, must be located in `mgmt_resource_group`"

  validation {
    condition     = length(var.key_vault_name) > 1 && length(var.key_vault_name) <= 24
    error_message = "Key vault names can have a max of 24 characters"
  }
  validation {
    condition     = can(regex("[A-Za-z0-9-]+", var.key_vault_name))
    error_message = "Invalid value, valid characters are A-Z, a-z, 0-9 and hyphens"
  }

}

variable "mgmt_resource_group" {
  type        = string
  description = "The resource group where you store management resources"
  default     = "iq3-basemanagement"

  validation {
    condition     = length(var.mgmt_resource_group) > 1 && length(var.mgmt_resource_group) <= 63
    error_message = "Resource group names can have a max of 63 characters"
  }
  validation {
    condition     = can(regex("[A-Za-z0-9-_]+", var.mgmt_resource_group))
    error_message = "Invalid value, valid characters are A-Z, a-z, 0-9, hyphens and underscores"
  }
}

variable "backup_retention_days" {
  type        = number
  description = "Backup retention days"
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35 && floor(var.backup_retention_days) == var.backup_retention_days
    error_message = "Accepted values: 7-35."
  }
}

variable "engine_version" {
  type        = string
  description = "version of mysql engine, check https://learn.microsoft.com/en-us/rest/api/mysql/flexibleserver/servers/create?tabs=HTTP#serverversion for supported versions"
  default     = null
}

variable "iops" {
  type        = string
  description = "IOPS"
  default     = "1000"
}

variable "size_gb" {
  type        = string
  description = "The disk size of your databases server"
  default     = "32"
}

variable "sku" {
  type        = string
  description = "The SKU of your server, [find the available SKUs here](https://azure.microsoft.com/en-us/pricing/details/mysql/flexible-server/)"
  default     = "GP_Standard_D4s_v3"
}

variable "zone_redundant" {
  type        = bool
  description = "Set to `true` if you want zone redundancy"
}

variable "databases" {
  type        = list(string)
  description = "a list of databases to be created on the server"
}

variable "administrator_login" {
  type        = string
  description = "Administrator username for your server"
  default     = "mysqladmin"

  validation {
    condition     = length(var.administrator_login) > 1 && length(var.administrator_login) <= 24
    error_message = "Names can have a max of 24 characters"
  }
  validation {
    condition     = can(regex("[A-Za-z0-9-]+", var.administrator_login))
    error_message = "Invalid value, valid characters are A-Z, a-z, 0-9 and hyphens"
  }
}

variable "virtual_network_resource_group_name" {
  type        = string
  default     = null
  description = "The name of the resource group containing the virtual network with your delegated subnet"
}

variable "virtual_network_name" {
  type        = string
  default     = null
  description = "The name of the VNET where your delegated subnet is located"
}

variable "delegated_subnet_name" {
  type        = string
  default     = null
  description = "The name of the delegated subnet to assign the service to"
}

variable "private_dns_zone_name" {
  type        = string
  default     = null
  description = "The name of your new private DNS zone"
}

variable "allow_external_access_mysql" {
  type = map(
    object({
      start = string,
      end   = string
    })
  )
  default     = null
  description = "map of dicts with ip addresses to allow in database firewall config"
}

variable "mysql_parameters" {
  type        = map(string)
  default     = null
  description = "map of mysql parameters to be configured on Azure database"
}
