# IP de las máquinas. La de la red NAT la da el DHCP (se lee del lease),
# la de la red de datos es estática (cloud-init)
output "balanceador" {
  value = {
    nombre   = "p1-balanceador"
    ip_nat   = try(libvirt_domain.p1-balanceador.network_interface[0].addresses[0], "No disponible")
    ip_datos = var.ip_datos_balanceador
  }
}

output "web" {
  value = [for i, d in libvirt_domain.p1-web : {
    nombre   = d.name
    ip_nat   = try(d.network_interface[0].addresses[0], "No disponible")
    ip_datos = var.ip_datos_webs[i]
  }]
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

output "nas" {
  value = {
    nombre   = "p1-nas"
    ip_nat   = try(libvirt_domain.p1-nas.network_interface[0].addresses[0], "No disponible")
    ip_datos = var.ip_datos_nas
  }
}
