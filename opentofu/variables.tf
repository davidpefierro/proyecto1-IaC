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

variable "memoria_php" {
  type        = number
  description = "Memoria en MiB de la máquina php"
  default     = 1024
}

variable "memoria_nas" {
  type        = number
  description = "Memoria en MiB de la máquina nas"
  default     = 512
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

# Direccionamiento
variable "red_nat" {
  type        = string
  description = "Rango de la red NAT (DHCP)"
  default     = "192.168.130.0/24"
}

# IP fijas que da el DHCP de la red NAT (reserva por MAC), así el nombre del
# virtual host apunta siempre a la misma IP aunque se destruya el escenario
variable "ip_nat_web" {
  type    = string
  default = "192.168.130.10"
}

variable "ip_nat_bd" {
  type    = string
  default = "192.168.130.20"
}

variable "ip_nat_php" {
  type    = string
  default = "192.168.130.30"
}

variable "ip_nat_nas" {
  type    = string
  default = "192.168.130.40"
}

# IP estáticas en la red de datos (se configuran con cloud-init)

variable "ip_datos_web" {
  type    = string
  default = "10.10.10.10"
}

variable "ip_datos_bd" {
  type    = string
  default = "10.10.10.20"
}

variable "ip_datos_php" {
  type    = string
  default = "10.10.10.30"
}

variable "ip_datos_nas" {
  type    = string
  default = "10.10.10.40"
}

variable "mascara_datos" {
  type    = number
  default = 24
}

# Disco de datos del NAS (en bytes). Se crea vacío y lo formatea Ansible
variable "tamano_disco_nas" {
  type        = number
  description = "Tamaño en bytes del disco de datos del nas"
  default     = 2147483648 # 2 GiB
}
