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

##############################################
# php — Debian 13 (PHP-FPM)
##############################################

resource "libvirt_volume" "p1-php-disk" {
  name             = "p1-php.qcow2"
  pool             = var.libvirt_pool_name
  base_volume_name = var.imagen_base_debian
  base_volume_pool = var.libvirt_pool_name
  format           = "qcow2"
}

resource "libvirt_cloudinit_disk" "p1-php-cloudinit" {
  name = "p1-php-cloudinit.iso"
  pool = var.libvirt_pool_name
  user_data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
    hostname  = "php"
    usuario   = "debian"
    clave_ssh = local.clave_ssh
  })
  network_config = templatefile("${path.module}/cloud-init/network-config.yaml.tftpl", {
    ip_datos = var.ip_datos_php
    mascara  = var.mascara_datos
  })
}

resource "libvirt_domain" "p1-php" {
  name   = "p1-php"
  memory = var.memoria_php
  vcpu   = var.vcpu

  # ens3: red NAT, para la salida a internet y para Ansible
  network_interface {
    network_id     = libvirt_network.p1-nat.id
    mac            = "52:54:00:13:00:30"
    addresses      = [var.ip_nat_php]
    wait_for_lease = true
  }

  # ens4: red de datos, por aquí le llegan las peticiones de Apache
  network_interface {
    network_id = libvirt_network.p1-datos.id
  }

  disk { volume_id = libvirt_volume.p1-php-disk.id }
  cloudinit = libvirt_cloudinit_disk.p1-php-cloudinit.id

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

##############################################
# nas — Debian 13 (servidor NFS)
##############################################

resource "libvirt_volume" "p1-nas-disk" {
  name             = "p1-nas.qcow2"
  pool             = var.libvirt_pool_name
  base_volume_name = var.imagen_base_debian
  base_volume_pool = var.libvirt_pool_name
  format           = "qcow2"
}

# Segundo disco, vacío, para lo que se comparte por NFS. Se destruye y se
# vuelve a crear con el escenario; lo formatea y lo rellena Ansible
resource "libvirt_volume" "p1-nas-datos" {
  name   = "p1-nas-datos.qcow2"
  pool   = var.libvirt_pool_name
  size   = var.tamano_disco_nas
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "p1-nas-cloudinit" {
  name = "p1-nas-cloudinit.iso"
  pool = var.libvirt_pool_name
  user_data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
    hostname  = "nas"
    usuario   = "debian"
    clave_ssh = local.clave_ssh
  })
  network_config = templatefile("${path.module}/cloud-init/network-config.yaml.tftpl", {
    ip_datos = var.ip_datos_nas
    mascara  = var.mascara_datos
  })
}

resource "libvirt_domain" "p1-nas" {
  name   = "p1-nas"
  memory = var.memoria_nas
  vcpu   = var.vcpu

  # ens3: red NAT, solo para instalar paquetes y para Ansible
  network_interface {
    network_id     = libvirt_network.p1-nat.id
    mac            = "52:54:00:13:00:40"
    addresses      = [var.ip_nat_nas]
    wait_for_lease = true
  }

  # ens4: red de datos, por aquí se sirve el NFS
  network_interface {
    network_id = libvirt_network.p1-datos.id
  }

  # vda: sistema, vdb: datos
  disk { volume_id = libvirt_volume.p1-nas-disk.id }
  disk { volume_id = libvirt_volume.p1-nas-datos.id }
  cloudinit = libvirt_cloudinit_disk.p1-nas-cloudinit.id

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}
