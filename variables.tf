variable "prefix" {
  description = "Resource name prefix."
  type        = string
  default     = "asr-test01"
}

variable "primary_location" {
  description = "Primary Azure region."
  type        = string
  default     = "koreacentral"
}

variable "dr_location" {
  description = "DR Azure region."
  type        = string
  default     = "japaneast"
}

variable "primary_vnet_cidr" {
  description = "Primary VNet CIDR."
  type        = string
  default     = "10.10.0.0/24"
}

variable "primary_subnet_cidr" {
  description = "Primary VM subnet CIDR."
  type        = string
  default     = "10.10.0.0/26"
}

variable "dr_vnet_cidr" {
  description = "DR VNet CIDR."
  type        = string
  default     = "10.20.0.0/24"
}

variable "dr_subnet_cidr" {
  description = "DR VM subnet CIDR."
  type        = string
  default     = "10.20.0.0/26"
}

variable "admin_username" {
  description = "Linux admin user name."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for the Linux VM."
  type        = string
  sensitive   = true
}

variable "admin_source_cidr" {
  description = "Source CIDR allowed to SSH. Use x.x.x.x/32 for your office/home public IP."
  type        = string
}

variable "vm_size" {
  description = "Primary VM size. ASR failover uses same or closest available size in DR region."
  type        = string
  default     = "Standard_B2s"
}

variable "traffic_manager_relative_name" {
  description = "Traffic Manager DNS relative name. Must be globally unique under trafficmanager.net."
  type        = string
  default     = "sonmap-asr-test01"
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    project = "Azure_Azure-Site-Recovery_test01"
    owner   = "sonmap"
    purpose = "asr-dr-lab"
  }
}
