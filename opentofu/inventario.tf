# Inventario de Ansible (ansible/hosts) generado con las IP del escenario.
# No se sube al repositorio: se vuelve a generar en cada tofu apply
resource "local_file" "inventario" {
  filename        = "${path.module}/../ansible/hosts"
  file_permission = "0644"
  content = templatefile("${path.module}/inventario.tftpl", {
    ip_balanceador       = try(libvirt_domain.p1-balanceador.network_interface[0].addresses[0], "")
    ip_datos_balanceador = var.ip_datos_balanceador
    webs = [for i, d in libvirt_domain.p1-web : {
      nombre   = "web${i + 1}"
      ip_nat   = try(d.network_interface[0].addresses[0], "")
      ip_datos = var.ip_datos_webs[i]
    }]
    ip_bd        = try(libvirt_domain.p1-bd.network_interface[0].addresses[0], "")
    ip_php       = try(libvirt_domain.p1-php.network_interface[0].addresses[0], "")
    ip_nas       = try(libvirt_domain.p1-nas.network_interface[0].addresses[0], "")
    ip_datos_bd  = var.ip_datos_bd
    ip_datos_php = var.ip_datos_php
    ip_datos_nas = var.ip_datos_nas
  })
}
