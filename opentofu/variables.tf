# Pool donde se crean los discos de las máquinas y las ISO de cloud-init
variable "libvirt_pool_name" {
  type        = string
  description = "Pool de almacenamiento de libvirt"
  default     = "default"
}

# Imágenes base (tienen que estar ya en el pool). Los discos de las
# máquinas son clones ligeros que las usan como backing file
variable "imagen_base_debian" {
  type        = string
  description = "Imagen base Debian 13 para el servidor web"
  default     = "debian13-base.qcow2"
}

variable "imagen_base_ubuntu" {
  type        = string
  description = "Imagen base Ubuntu 26.04 para el servidor de base de datos"
  default     = "ubuntu2604-base.qcow2"
}

# Memoria (MiB) y CPUs de cada máquina
variable "memoria_web" {
  type        = number
  description = "Memoria en MiB de la máquina web"
  default     = 1024
}

variable "memoria_bd" {
  type        = number
  description = "Memoria en MiB de la máquina bd"
  default     = 1024
}

variable "vcpu" {
  type        = number
  description = "Número de CPUs de cada máquina"
  default     = 1
}

# Clave pública que se mete en las máquinas para entrar por ssh (y para Ansible)
variable "clave_ssh" {
  type        = string
  description = "Ruta de la clave pública ssh"
  default     = "~/.ssh/id_rsa.pub"
}
