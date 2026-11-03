# Inventario de Ansible (ansible/hosts) generado con las IP del escenario.
# No se sube al repositorio: se vuelve a generar en cada tofu apply
resource "local_file" "inventario" {
  filename        = "${path.module}/../ansible/hosts"
  file_permission = "0644"
  content = templatefile("${path.module}/inventario.tftpl", {
    ip_web       = try(libvirt_domain.p1-web.network_interface[0].addresses[0], "")
    ip_bd        = try(libvirt_domain.p1-bd.network_interface[0].addresses[0], "")
    ip_datos_web = var.ip_datos_web
    ip_datos_bd  = var.ip_datos_bd
  })
}
