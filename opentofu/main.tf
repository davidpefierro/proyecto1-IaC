locals {
  clave_ssh = trimspace(file(pathexpand(var.clave_ssh)))
}

##############################################
# web — Debian 13 (Apache + PHP)
##############################################

# Clon ligero: solo guarda los cambios respecto a la imagen base
resource "libvirt_volume" "p1-web-disk" {
  name             = "p1-web.qcow2"
  pool             = var.libvirt_pool_name
  base_volume_name = var.imagen_base_debian
  base_volume_pool = var.libvirt_pool_name
  format           = "qcow2"
}

resource "libvirt_cloudinit_disk" "p1-web-cloudinit" {
  name = "p1-web-cloudinit.iso"
  pool = var.libvirt_pool_name
  user_data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
    hostname  = "web"
    usuario   = "debian"
    clave_ssh = local.clave_ssh
  })
  network_config = templatefile("${path.module}/cloud-init/network-config.yaml.tftpl", {
    ip_datos = var.ip_datos_web
    mascara  = var.mascara_datos
  })
}

resource "libvirt_domain" "p1-web" {
  name   = "p1-web"
  memory = var.memoria_web
  vcpu   = var.vcpu

  # ens3: red NAT, IP por DHCP (reservada por MAC)
  network_interface {
    network_id     = libvirt_network.p1-nat.id
    mac            = "52:54:00:13:00:10"
    addresses      = [var.ip_nat_web]
    wait_for_lease = true
  }

  # ens4: red de datos, IP estática puesta por cloud-init
  network_interface {
    network_id = libvirt_network.p1-datos.id
  }

  disk { volume_id = libvirt_volume.p1-web-disk.id }
  cloudinit = libvirt_cloudinit_disk.p1-web-cloudinit.id

  # Las imágenes cloud esperan consola serie (y así se puede entrar con
  # virsh console si falla la red)
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

##############################################
# bd — Ubuntu 26.04 (MariaDB)
##############################################

resource "libvirt_volume" "p1-bd-disk" {
  name             = "p1-bd.qcow2"
  pool             = var.libvirt_pool_name
  base_volume_name = var.imagen_base_ubuntu
  base_volume_pool = var.libvirt_pool_name
  format           = "qcow2"
}

resource "libvirt_cloudinit_disk" "p1-bd-cloudinit" {
  name = "p1-bd-cloudinit.iso"
  pool = var.libvirt_pool_name
  user_data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
    hostname  = "bd"
    usuario   = "ubuntu"
    clave_ssh = local.clave_ssh
  })
  network_config = templatefile("${path.module}/cloud-init/network-config.yaml.tftpl", {
    ip_datos = var.ip_datos_bd
    mascara  = var.mascara_datos
  })
}

resource "libvirt_domain" "p1-bd" {
  name   = "p1-bd"
  memory = var.memoria_bd
  vcpu   = var.vcpu

  network_interface {
    network_id     = libvirt_network.p1-nat.id
    mac            = "52:54:00:13:00:20"
    addresses      = [var.ip_nat_bd]
    wait_for_lease = true
  }

  network_interface {
    network_id = libvirt_network.p1-datos.id
  }

  disk { volume_id = libvirt_volume.p1-bd-disk.id }
  cloudinit = libvirt_cloudinit_disk.p1-bd-cloudinit.id

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}
