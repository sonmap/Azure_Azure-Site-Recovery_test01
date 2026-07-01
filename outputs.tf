output "service_url" {
  description = "Same external service URL through Azure Traffic Manager."
  value       = "http://${azurerm_traffic_manager_profile.this.fqdn}"
}

output "traffic_manager_fqdn" {
  description = "Traffic Manager FQDN. Connect your custom DNS CNAME to this value."
  value       = azurerm_traffic_manager_profile.this.fqdn
}

output "primary_lb_public_ip" {
  description = "Korea Central Public Load Balancer IP."
  value       = azurerm_public_ip.primary_lb.ip_address
}

output "jpe_lb_public_ip" {
  description = "Japan East Public Load Balancer IP."
  value       = azurerm_public_ip.dr_lb.ip_address
}

output "primary_vm_name" {
  description = "Primary nginx VM name."
  value       = azurerm_linux_virtual_machine.primary.name
}

output "primary_resource_group_name" {
  description = "Primary resource group."
  value       = azurerm_resource_group.primary.name
}

output "dr_resource_group_name" {
  description = "DR resource group."
  value       = azurerm_resource_group.dr.name
}

output "recovery_services_vault_name" {
  description = "Recovery Services Vault name."
  value       = azurerm_recovery_services_vault.dr.name
}

output "dr_lb_name" {
  description = "Japan East Public Load Balancer name."
  value       = azurerm_lb.dr.name
}

output "dr_lb_backend_pool_name" {
  description = "Japan East LB backend pool name. Use this in the post-failover attach script."
  value       = azurerm_lb_backend_address_pool.dr.name
}
