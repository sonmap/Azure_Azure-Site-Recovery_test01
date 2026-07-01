# Standard Public Load Balancer outbound rules.
# These allow the primary VM to reach Ubuntu package repositories during cloud-init.
# The DR rule is ready for the recovered VM after its NIC is attached to the DR backend pool.

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
