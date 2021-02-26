output "synapse_sql_server" {
  value = azurerm_synapse_workspace.synapse.connectivity_endpoints["sql"]
}
