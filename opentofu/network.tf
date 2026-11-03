# Red NAT con DHCP: desde aquí se accede al servidor web y las máquinas
# tienen salida a internet. Ansible también entra por esta red
resource "libvirt_network" "p1-nat" {
  name      = "p1-nat"
  mode      = "nat"
  domain    = "p1.local"
  addresses = [var.red_nat]
  dhcp { enabled = true }
  dns { enabled = true }
  autostart = true
}

# Red de datos muy aislada (mode=none): sin DHCP, sin router y sin salida.
# Solo la usan web y bd para hablar entre ellas, con IP estáticas
resource "libvirt_network" "p1-datos" {
  name      = "p1-datos"
  mode      = "none"
  autostart = true
}
