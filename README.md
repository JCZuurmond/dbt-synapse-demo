# Data Build Tool Azure Synapse Analytics Demo

This repository demos how to use data build tool ([dbt]) with [Azure Synapse
Analytics]. In this repository we recreate the [jaffle shop] tutorial with a
Synapse data warehouse as backend.

# Prerequisites and installation overview

[Azure Synapse Analytics] is a data warehouse service on the [Azure cloud]. We expect you
to have an Azure account. If not, you can create one for [free](https://azure.microsoft.com/en-us/free/).

Everything in this repository is ran from the command line. We expect some basic
knowledge about using the command line. The following tools are used, follow
links for installation instructions:

- [Azure cli] : 
  The command line interface for the [Azure cloud].
- [Terraform cli] : 
  The command line interface to [Terraform]. An infrastructure-as-code tool we
  use to provision Synapse and related resources.
- [dbt cli] :
  The command line tool for [dbt].
- [dbt Synapse adapter] :
  A [dbt] adapter for [Azure Synapse Analytics].

# Login to Azure

Before we start make sure you are logged in:

``` bash
az login     # opens a browser with login page
```

``` bash
az account set --subscription <subscription id>
```

For more info, see [this page](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli).

# Create a Synapse workspace with Terraform

We use [Terraform] to create a [Azure Synapse Analytics] workspace. Besides the
workspace itself the following resources are created:

- resource group :
  All resources related to this demo are kept in this resource group.
- [Azure Synapse Analytics] workspace :
  The [Azure Synapse Analytics] workspace.
- dedicated SQL pool : 
  A dedicated SQL pool. **NOTE: you pay for a dedicated pool even if you do not
  use it. The smallest size is chosen in this demo repo 'DW100C'.**
- storage account with data lake gen2 file system:
  A (hierarchical namespace) storage account associated with the workspace.
- firewall rule :
  A firewall rule with your IP address, so that you can access the SQL server.
- keyvault : 
  In the keyvault the sql administrator password is kept. Look for the
  `synapse-sql-adminstrator-password` secret. The login name is `sqladminuser`.

For a more detailed overview of what is created, see [here](terraform/main.tf).

The first we initialize Terraform with `init`:

``` bash
terraform -chdir=terraform/ init
```

After that, we run `plan` to see which resources will be created. You can change
the `resource_group_name` and `resource_group_location` to your liking:

``` bash
terraform -chdir=terraform/ plan \
  -var="resource_group_name=dbt-synapse-demo" \ 
  -var="resource_group_location=westeurope" \
  -out terraform.tfplan
```

Finally, to create all resources we run `apply`:

```bash
terraform -chdir=terraform/ apply terraform.tfplan
```

# Jaffle shop with data built tool (dbt)

This repository uses the [jaffle shop] tutorial which is part of dbt. The
tutorial is initialized with:

```bash
dbt init jaffle-shop
```

First, we need to define a [dbt profile](profiles.yml):

``` yaml
$ cat profiles.yml
default:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 17 for SQL Server'
      server: SYNAPSE_SQL_SERVER
      port: 1433
      database: master
      schema: dbt
      authentication: CLI
```

Replace `SYNAPSE_SQL_SERVER` with the server name of the dedicated SQL server we 
provisioned with Terraform. The serve name can be easily retrieved with:

``` bash
terraform -chdir=terraform/ output synapse_sql_server
```

If you prefer to never leave the command line, run:

``` bash
sed -i -e \
  s/SYNAPSE_SQL_SERVER/$(terraform -chdir=terraform/ output synapse_sql_server)/g \
  profiles.yml
```

Check if your set-up is working correctly:

``` bash
dbt debug \
  --project-dir jaffle-shop/ \
  --profiles-dir .
```

All responses should show `OK`. You should be able to perform your first dbt run
with:

``` bash
dbt run \
  --project-dir jaffle-shop/ \
  --profiles-dir .
```

For the remainder of the tutorial refer to [this page](https://docs.getdbt.com/tutorial/create-a-project-dbt-cli#perform-your-first-dbt-run).

# Clean up

When you are done with the demo, you can clean up the resources with:

```bash
terraform -chdir=terraform/ plan \
  -destroy \
  -var="resource_group_name=dbt-synapse-demo"  \ 
  -var="resource_group_location=westeurope" \
  -out terraform.tfplan

terraform -chdir=terraform/ apply terraform.tfplan
```

NOTE: you pay for a dedicated pool even if you do not use it. The smallest size
is chosen in this demo repo 'DW100C'.

[Azure cli]: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli "Azure cli"
[Azure cloud]: https://azure.microsoft.com/en-us/ "Azure cloud"
[Azure Synapse Analytics]: https://azure.microsoft.com/en-us/services/synapse-analytics/ "Azure Synapse Analytics"
[dbt]: https://www.getdbt.com/ "data build tool"
[dbt cli]: https://docs.getdbt.com/dbt-cli/installation/ "dbt cli"
[dbt Synapse adapter]: https://github.com/dbt-msft/dbt-synapse "dbt Synapse adapter"
[jaffle shop]: https://docs.getdbt.com/tutorial/setting-up "Jaffle Shop"
[Terraform]: https://www.terraform.io/ "Terraform"
[Terraform cli]: https://learn.hashicorp.com/tutorials/terraform/install-cli "Terraform cli"
