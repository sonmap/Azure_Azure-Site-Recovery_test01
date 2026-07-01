resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

locals {
  suffix = random_string.suffix.result

  primary_rg_name = "rg-${var.prefix}-krc"
  dr_rg_name      = "rg-${var.prefix}-jpe"

  primary_vnet_name = "vnet-${var.prefix}-krc"
  dr_vnet_name      = "vnet-${var.prefix}-jpe"

  primary_subnet_name = "snet-web-krc"
  dr_subnet_name      = "snet-web-jpe"

  primary_lb_name = "lb-${var.prefix}-krc"
  dr_lb_name      = "lb-${var.prefix}-jpe"

  primary_be_pool_name = "be-${var.prefix}-krc"
  dr_be_pool_name      = "be-${var.prefix}-jpe"
}

resource "azurerm_resource_group" "primary" {
  name     = local.primary_rg_name
  location = var.primary_location
  tags     = var.tags
}

resource "azurerm_resource_group" "dr" {
  name     = local.dr_rg_name
  location = var.dr_location
  tags     = var.tags
}

resource "azurerm_virtual_network" "primary" {
  name                = local.primary_vnet_name
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  address_space       = [var.primary_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_virtual_network" "dr" {
  name                = local.dr_vnet_name
  location            = azurerm_resource_group.dr.location
  resource_group_name = azurerm_resource_group.dr.name
  address_space       = [var.dr_vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "primary_web" {
  name                 = local.primary_subnet_name
  resource_group_name  = azurerm_resource_group.primary.name
  virtual_network_name = azurerm_virtual_network.primary.name
  address_prefixes     = [var.primary_subnet_cidr]
}

resource "azurerm_subnet" "dr_web" {
  name                 = local.dr_subnet_name
  resource_group_name  = azurerm_resource_group.dr.name
  virtual_network_name = azurerm_virtual_network.dr.name
  address_prefixes     = [var.dr_subnet_cidr]
}

resource "azurerm_network_security_group" "primary_web" {
  name                = "nsg-${var.prefix}-web-krc"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTP-From-Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-Admin"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "dr_web" {
  name                = "nsg-${var.prefix}-web-jpe"
  location            = azurerm_resource_group.dr.location
  resource_group_name = azurerm_resource_group.dr.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTP-From-Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-Admin"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "primary_web" {
  subnet_id                 = azurerm_subnet.primary_web.id
  network_security_group_id = azurerm_network_security_group.primary_web.id
}

resource "azurerm_subnet_network_security_group_association" "dr_web" {
  subnet_id                 = azurerm_subnet.dr_web.id
  network_security_group_id = azurerm_network_security_group.dr_web.id
}

resource "azurerm_public_ip" "primary_lb" {
  name                = "pip-${var.prefix}-lb-krc"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.prefix}-krc-${local.suffix}"
  tags                = var.tags
}

resource "azurerm_public_ip" "dr_lb" {
  name                = "pip-${var.prefix}-lb-jpe"
  location            = azurerm_resource_group.dr.location
  resource_group_name = azurerm_resource_group.dr.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.prefix}-jpe-${local.suffix}"
  tags                = var.tags
}

resource "azurerm_lb" "primary" {
  name                = local.primary_lb_name
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "fe-krc"
    public_ip_address_id = azurerm_public_ip.primary_lb.id
  }
}

resource "azurerm_lb" "dr" {
  name                = local.dr_lb_name
  location            = azurerm_resource_group.dr.location
  resource_group_name = azurerm_resource_group.dr.name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "fe-jpe"
    public_ip_address_id = azurerm_public_ip.dr_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "primary" {
  name            = local.primary_be_pool_name
  loadbalancer_id = azurerm_lb.primary.id
}

resource "azurerm_lb_backend_address_pool" "dr" {
  name            = local.dr_be_pool_name
  loadbalancer_id = azurerm_lb.dr.id
}

resource "azurerm_lb_probe" "primary_http" {
  name            = "probe-http"
  loadbalancer_id = azurerm_lb.primary.id
  protocol        = "Http"
  port            = 80
  request_path    = "/health"
}

resource "azurerm_lb_probe" "dr_http" {
  name            = "probe-http"
  loadbalancer_id = azurerm_lb.dr.id
  protocol        = "Http"
  port            = 80
  request_path    = "/health"
}

resource "azurerm_lb_rule" "primary_http" {
  name                           = "rule-http-80"
  loadbalancer_id                = azurerm_lb.primary.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "fe-krc"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.primary.id]
  probe_id                       = azurerm_lb_probe.primary_http.id
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "dr_http" {
  name                           = "rule-http-80"
  loadbalancer_id                = azurerm_lb.dr.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "fe-jpe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.dr.id]
  probe_id                       = azurerm_lb_probe.dr_http.id
  disable_outbound_snat          = true
}

resource "azurerm_network_interface" "primary_vm" {
  name                = "nic-${var.prefix}-web01-krc"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.primary_web.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "primary_vm" {
  network_interface_id    = azurerm_network_interface.primary_vm.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.primary.id
}

resource "azurerm_linux_virtual_machine" "primary" {
  name                = "vm-${var.prefix}-web01-krc"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.primary_vm.id
  ]
  custom_data = base64encode(templatefile("${path.module}/cloud-init/nginx.yaml", {
    role_label = "Korea Central PRIMARY"
  }))
  tags = merge(var.tags, {
    role = "primary-nginx"
  })

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "osdisk-${var.prefix}-web01-krc"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface_backend_address_pool_association.primary_vm
  ]
}

resource "azurerm_traffic_manager_profile" "this" {
  name                   = "tm-${var.prefix}-${local.suffix}"
  resource_group_name    = azurerm_resource_group.primary.name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = var.traffic_manager_relative_name
    ttl           = 30
  }

  monitor_config {
    protocol = "HTTP"
    port     = 80
    path     = "/health"
  }

  tags = var.tags
}

resource "azurerm_traffic_manager_azure_endpoint" "primary" {
  name               = "ep-krc-primary-lb"
  profile_id         = azurerm_traffic_manager_profile.this.id
  target_resource_id = azurerm_public_ip.primary_lb.id
  priority           = 1
  enabled            = true
}

resource "azurerm_traffic_manager_azure_endpoint" "dr" {
  name               = "ep-jpe-dr-lb"
  profile_id         = azurerm_traffic_manager_profile.this.id
  target_resource_id = azurerm_public_ip.dr_lb.id
  priority           = 2
  enabled            = true
}

resource "azurerm_recovery_services_vault" "dr" {
  name                = "rsv-${var.prefix}-jpe-${local.suffix}"
  location            = azurerm_resource_group.dr.location
  resource_group_name = azurerm_resource_group.dr.name
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_storage_account" "asr_cache" {
  name                     = "st${replace(var.prefix, "-", "")}${local.suffix}krc"
  resource_group_name      = azurerm_resource_group.primary.name
  location                 = azurerm_resource_group.primary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_site_recovery_fabric" "primary" {
  name                = "asr-fabric-krc"
  resource_group_name = azurerm_resource_group.dr.name
  recovery_vault_name = azurerm_recovery_services_vault.dr.name
  location            = azurerm_resource_group.primary.location
}

resource "azurerm_site_recovery_fabric" "dr" {
  name                = "asr-fabric-jpe"
  resource_group_name = azurerm_resource_group.dr.name
  recovery_vault_name = azurerm_recovery_services_vault.dr.name
  location            = azurerm_resource_group.dr.location

  depends_on = [
    azurerm_site_recovery_fabric.primary
  ]
}

resource "azurerm_site_recovery_protection_container" "primary" {
  name                 = "asr-pc-krc"
  resource_group_name  = azurerm_resource_group.dr.name
  recovery_vault_name  = azurerm_recovery_services_vault.dr.name
  recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
}

resource "azurerm_site_recovery_protection_container" "dr" {
  name                 = "asr-pc-jpe"
  resource_group_name  = azurerm_resource_group.dr.name
  recovery_vault_name  = azurerm_recovery_services_vault.dr.name
  recovery_fabric_name = azurerm_site_recovery_fabric.dr.name
}

resource "azurerm_site_recovery_replication_policy" "this" {
  name                                                 = "asr-policy-24h"
  resource_group_name                                  = azurerm_resource_group.dr.name
  recovery_vault_name                                  = azurerm_recovery_services_vault.dr.name
  recovery_point_retention_in_minutes                  = 24 * 60
  application_consistent_snapshot_frequency_in_minutes = 4 * 60
}

resource "azurerm_site_recovery_protection_container_mapping" "primary_to_dr" {
  name                                      = "asr-pcmap-krc-to-jpe"
  resource_group_name                       = azurerm_resource_group.dr.name
  recovery_vault_name                       = azurerm_recovery_services_vault.dr.name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.primary.name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.dr.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.this.id
}

resource "azurerm_site_recovery_network_mapping" "primary_to_dr" {
  name                        = "asr-netmap-krc-to-jpe"
  resource_group_name         = azurerm_resource_group.dr.name
  recovery_vault_name         = azurerm_recovery_services_vault.dr.name
  source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.dr.name
  source_network_id           = azurerm_virtual_network.primary.id
  target_network_id           = azurerm_virtual_network.dr.id
}

resource "azurerm_site_recovery_replicated_vm" "primary" {
  name                                      = "asr-vm-${var.prefix}-web01"
  resource_group_name                       = azurerm_resource_group.dr.name
  recovery_vault_name                       = azurerm_recovery_services_vault.dr.name
  source_recovery_fabric_name               = azurerm_site_recovery_fabric.primary.name
  source_vm_id                              = azurerm_linux_virtual_machine.primary.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.this.id
  source_recovery_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  target_resource_group_id                  = azurerm_resource_group.dr.id
  target_recovery_fabric_id                 = azurerm_site_recovery_fabric.dr.id
  target_recovery_protection_container_id   = azurerm_site_recovery_protection_container.dr.id

  managed_disk {
    disk_id                    = azurerm_linux_virtual_machine.primary.os_disk[0].id
    staging_storage_account_id = azurerm_storage_account.asr_cache.id
    target_resource_group_id   = azurerm_resource_group.dr.id
    target_disk_type           = "Premium_LRS"
    target_replica_disk_type   = "Premium_LRS"
  }

  network_interface {
    source_network_interface_id = azurerm_network_interface.primary_vm.id
    target_subnet_name          = azurerm_subnet.dr_web.name
  }

  depends_on = [
    azurerm_site_recovery_protection_container_mapping.primary_to_dr,
    azurerm_site_recovery_network_mapping.primary_to_dr,
    azurerm_linux_virtual_machine.primary
  ]

  timeouts {
    create = "5h30m"
    update = "5h30m"
    delete = "2h"
  }
}
