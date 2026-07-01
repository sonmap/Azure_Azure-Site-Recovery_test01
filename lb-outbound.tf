# Standard Public Load Balancer outbound rules.
#
# Standard Public Load Balancer does not provide default outbound internet access.
# These outbound rules allow the primary VM, and later an ASR-recovered DR VM after NIC backend-pool attachment,
# to reach Ubuntu package repositories and Azure endpoints during Ansible Run Command based configuration.

resource "azurerm_lb_outbound_rule" "primary" {
  name                    = "outbound-internet"
  loadbalancer_id         = azurerm_lb.primary.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.primary.id

  frontend_ip_configuration {
    name = "fe-krc"
  }
}

resource "azurerm_lb_outbound_rule" "dr" {
  name                    = "outbound-internet"
  loadbalancer_id         = azurerm_lb.dr.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.dr.id

  frontend_ip_configuration {
    name = "fe-jpe"
  }
}
