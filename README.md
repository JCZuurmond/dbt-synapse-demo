# DBT Synapse Demo

## Infrastructure

We use [Terraform](https://www.terraform.io/) to provision the infrastructure
for this demo repo. This repo uses the [Azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) 
for authentication. Before running the following commands make sure [you are logged
in and set the right subscription](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)

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


