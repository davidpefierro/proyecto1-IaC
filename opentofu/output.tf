# IP de las máquinas. La de la red NAT la da el DHCP (se lee del lease),
# la de la red de datos es estática (cloud-init)
output "web" {
  value = {
    nombre   = "p1-web"
    ip_nat   = try(libvirt_domain.p1-web.network_interface[0].addresses[0], "No disponible")
    ip_datos = var.ip_datos_web
  }
}

output "bd" {
  value = {
    nombre   = "p1-bd"
    ip_nat   = try(libvirt_domain.p1-bd.network_interface[0].addresses[0], "No disponible")
    ip_datos = var.ip_datos_bd
  }
}

output "php" {
  value = {
    nombre   = "p1-php"
    ip_nat   = try(libvirt_domain.p1-php.network_interface[0].addresses[0], "No disponible")
    ip_datos = var.ip_datos_php
  }
}
