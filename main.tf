resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "vpnVMRG-${var.admin_name}"
  tags = {
    "your name" = var.admin_name
  }  
}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "${var.admin_name}-vpnVMVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    "your name" = var.admin_name
  }   
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "${var.admin_name}-vpnVMSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${var.admin_name}-vpnVMPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags = {
    "your name" = var.admin_name
  }   
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${var.admin_name}-vpnVMNSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    "your name" = var.admin_name
  }   

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  } 
  security_rule {
    name                       = "VPN"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = var.vpn_port_number
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }   
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "${var.admin_name}-vpnVMNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    "your name" = var.admin_name
  }   

  ip_configuration {
    name                          = "${var.admin_name}-vpnVM_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "${var.admin_name}diag"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    "your name" = var.admin_name
  }   
}

# Create (and display) an SSH key
# resource "tls_private_key" "example_ssh" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "${var.admin_name}-vpnVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_B1s"
  tags = {
    "your name" = var.admin_name
  }   

  os_disk {
    name                 = "${var.admin_name}-vpnVMOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  computer_name                   = "${var.admin_name}-vpnVM"
  admin_username                  = var.admin_name

  disable_password_authentication = false
  admin_password                  = var.admin_password

  # disable_password_authentication = true
  # admin_ssh_key {
  #   username   = "azureuser"
  #   public_key = tls_private_key.example_ssh.public_key_openssh
  # }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
  
  connection {
    type     = "ssh"
    user     = var.admin_name
    password = var.admin_password
    host     = self.public_ip_address
  }  
  
  provisioner "remote-exec" {
    inline = [
      "echo ${var.admin_password} | sudo su",
      "sudo apt-get update -y && apt-get upgrade -y",
      "sudo apt-get install docker.io -y",
      "sudo docker run -itd --cap-add=NET_ADMIN -p ${var.vpn_port_number}:1194/udp -p 80:8080/tcp -e HOST_ADDR=$(curl -s https://api.ipify.org) --name dockovpn alekslitvinenk/openvpn"
    ]
  }
}