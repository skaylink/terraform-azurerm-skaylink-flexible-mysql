# Skaylink Terraform module; Flexible MySQL

This module will deploy a flexible MySQL instance on Azure, which is deemed to replace the older single-server offering in the long run.

## Example

Below is an example of the module in use.

```terraform
  module "skaylink-flexible-mysql" {
    resource_group_name   = "my-project-rg"
    usecase               = "my-use-case-that-is-less-than-50-characters"
    location              = "norwayeast"
    environment           = "dev"
    key_vault_name        = "my-kv-name"
    mgmt_resource_group   = "my-kv-resource-group"
    backup_retention_days = 35
    size_gb               = "20"
    sku                   = "MO_Standard_E2ds_v5"
    zone_redundant        = true
    databases             = ["my-awesome-db-1", "my-awesome-db-2", "my-awesome-db-3"]
    administrator_login   = "iamgroot"
  }
```
