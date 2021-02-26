output "synapse_sql_on_demand_server" {
  value = azurerm_synapse_workspace.synapse.connectivity_endpoints["sqlOnDemand"]
}
