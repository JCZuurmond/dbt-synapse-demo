# DBT Synapse Demo

## Infrastructure

### Provision the infastructure

We use [Terraform](https://www.terraform.io/) to provision the infrastructure
for this demo repo. Terraform needs a [service
principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals#service-principal-object)
(SP) as identity to provision the resources. To limit the rights of the SP, this
demo repo first creates a resource groups and scopes the SP to that resource group.

First, create a resource group:

```bash
az group creeate \
    --name <resource group name> \
    --location <location>    # run `az account list-locations` to see locations
```

Then, create the SP and store the response of this command somewhere.

```bash
az ad sp create-for-rbac \
    --name <service principal name> \
    --sdk-auth \
    --role "Owner" \      # Owner is needed to create RBAC roles
    --scopes /subscriptions/<subscription id>/resourceGroups/<resource group name>/
```
