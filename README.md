# Data Build Tool Azure Synapse Analytics Demo

This repository demos how to use data build tool (dbt) with Azure Synapse
Analytics. In this repository we recreate the
[`jaffle-shop`](https://docs.getdbt.com/tutorial/setting-up) tutorial with
Synapse as backend.

# Infrastructure

We use [Terraform](https://www.terraform.io/) to provision the infrastructure
for this demo repo. This repo uses the [Azure
cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) for
authentication. Before running the following commands make sure [you are logged
in to Azure and set the right
subscription](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)
, and you [installed the terraform
cli](https://learn.hashicorp.com/tutorials/terraform/install-cli).

First run `init`:

```bash
terraform -chdir=terraform/ init
```

Then run `plan` to see which resources will be created.

```bash
terraform -chdir=terraform/ plan \
  -var="resource_group_name=dbt-synapse-demo"  \ 
  -var="resource_group_location=westeurope" \
  -out terraform.tfplan
```

Finally, run `apply` to create the resources.

```bash
terraform -chdir=terraform/ apply terraform.tfplan
```

# DBT

First [install the dbt cli](https://docs.getdbt.com/dbt-cli/installation). 

The tutorial is initialized with:

```bash
dbt init jaffle-shop
```

We need to define a [dbt profile](dbt/profiles.yml):

``` yaml
$ cat dbt/profiles.yml
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

Replace `SYNAPSE_SQL_SERVER` with the server name of the default SQL
on demand created with the Synapse work space. It can be easily retrieved with:

``` bash
terraform -chdir=terraform/ output synapse_sql_server
```

Or, if you like to stay on the command line, run:

``` bash
sed -i -e \
  s/SYNAPSE_SQL_SERVER/$(terraform -chdir=terraform/ output synapse_sql_server)/g \
  profiles.yml
```

Finally, we need to install the `dbt-sqlserver` adapter:

``` bash
pip install dbt-synapse
```

To validate the set-up is working run:

``` bash
dbt debug \
  --project-dir jaffle-shop/ \
  --profiles-dir .
```

This should show `OK`.


# Clean up

When you are done with this demo repo, you can clean up the resources with:

```bash
terraform -chdir=terraform/ plan \
  -destroy \
  -var="resource_group_name=dbt-synapse-demo"  \ 
  -var="resource_group_location=westeurope" \
  -out terraform.tfplan

terraform -chdir=terraform/ apply terraform.tfplan
```
