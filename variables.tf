variable "resource_group_location" {
  default     = "japaneast"
  description = "Location of the resource group."
}

variable "vpn_port_number" {
  default     = "12345"
  description = "VPN Port Number"
}

variable "admin_name" {
  default     = "cyrus"
  description = "User name to login to the VM"
}

variable "admin_password" {
  default     = "Password1234!"
  description = "Password to login to the VM"
}