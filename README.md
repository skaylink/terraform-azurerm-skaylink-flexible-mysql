# Skaylink Terraform module; Flexible MySQL

This module will deploy a flexible MySQL instance on Azure, which is deemed to replace the older single-server offering in the long run.

## Example

Below is an example of the module in use.

```terraform
  module "skaylink-flexible-mysql" {
    source                      = "skaylink/skaylink-flexible-mysql/azurerm"
    version                     = "1.0.4"
    resource_group_name         = "my-project-rg"
    usecase                     = "my-use-case-that-is-less-than-50-characters"
    location                    = "norwayeast"
    environment                 = "dev"
    key_vault_name              = "my-kv-name"
    mgmt_resource_group         = "my-kv-resource-group"
    backup_retention_days       = 35
    engine_version              = "8.0"
    size_gb                     = "20"
    sku                         = "MO_Standard_E2ds_v5"
    zone_redundant              = true
    databases                   = ["my-awesome-db-1", "my-awesome-db-2", "my-awesome-db-3"]
    administrator_login         = "iamgroot"
    allow_external_access_mysql = {
      "ip_range-name" : {
        start : "start-IP-range",
        end : "end-IP-range"
      }
    }
    mysql_parameters            = {
      auto_increment_increment: 2
      auto_increment_offset : 2
    }
  }
```

If you want to assign a delegated subnet, this will also create a virtual network link, and a private DNS zone.

Once you populate `delegated_subnet_name`, the following values must also be populated: `virtual_network_name`, `virtual_network_resource_group_name` and `private_dns_zone_name`.

This is an example of how this may look:


```terraform
  module "skaylink-flexible-mysql" {
    source                              = "skaylink/skaylink-flexible-mysql/azurerm"
    version                             = "1.0.4"
    resource_group_name                 = "my-project-rg"
    usecase                             = "my-use-case-that-is-less-than-50-characters"
    location                            = "norwayeast"
    environment                         = "dev"
    key_vault_name                      = "my-kv-name"
    mgmt_resource_group                 = "my-kv-resource-group"
    backup_retention_days               = 35
    size_gb                             = "20"
    sku                                 = "MO_Standard_E2ds_v5"
    zone_redundant                      = true
    databases                           = ["my-awesome-db-1", "my-awesome-db-2", "my-awesome-db-3"]
    administrator_login                 = "iamgroot"
    delegated_subnet_name               = "thenameofmydelegatedsubnet"
    virtual_network_name                = "myvnet"
    virtual_network_resource_group_name = "my-vnet-rg"
    private_dns_zone_name               = "myprivatednszoneprefix"
  }
```
