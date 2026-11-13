# Proyecto 1: Infraestructura como código

Escenario con OpenTofu (libvirt/KVM) configurado con Ansible para poner en producción
el libro de visitas [guestbook_php](https://github.com/josedom24/guestbook_php) con MariaDB.

## Escenario

| Máquina | Sistema       | Red NAT (DHCP)   | Red de datos  | Función             |
|---------|---------------|------------------|---------------|---------------------|
| `web`   | Debian 13     | 192.168.130.10   | 10.10.10.10   | Apache (sin PHP)    |
| `php`   | Debian 13     | 192.168.130.30   | 10.10.10.30   | PHP-FPM             |
| `bd`    | Ubuntu 26.04  | 192.168.130.20   | 10.10.10.20   | MariaDB             |
| `nas`   | Debian 13     | 192.168.130.40   | 10.10.10.40   | NFS (la aplicación) |

- **p1-nat** (`192.168.130.0/24`): red NAT con DHCP. Las IP se reservan por MAC para que no
  cambien al recrear el escenario. Por aquí se accede a la web y entra Ansible.
- **p1-datos** (`10.10.10.0/24`): red muy aislada (sin DHCP ni salida), con IP estáticas
  puestas por cloud-init. Por ella Apache pasa los `.php` a PHP-FPM, PHP-FPM se conecta a MariaDB
  y `web` y `php` montan la aplicación del `nas`.

### PHP-FPM en otra máquina (modificación 1)

Apache no ejecuta PHP: los ficheros `.php` se mandan con `mod_proxy_fcgi` a PHP-FPM, que escucha en
`10.10.10.30:9000` y solo acepta conexiones de `web`. Las dos máquinas necesitan la aplicación en la misma
ruta (`/var/www/guestbook`): Apache para los estáticos y el `.htaccess`, y PHP-FPM para ejecutar los ficheros
que le indica Apache. El usuario de MariaDB solo puede entrar desde `php`.

### NAS con NFS (modificación 2)

La aplicación está una sola vez, en el `nas`, y `web` y `php` la montan por NFS en `/var/www/guestbook`.

- El `nas` tiene un segundo disco (`vdb`, 2 GB) que crea tofu vacío. Ansible lo formatea en ext4 si no tiene
  sistema de ficheros, lo monta en `/srv/nfs` y clona ahí la aplicación con su `config.php`. Con
  `tofu destroy` se borra y con `tofu apply` + el playbook queda igual: no hay nada en él que no salga del
  repositorio (los mensajes están en MariaDB).
- Exporta `/srv/nfs/guestbook` solo a `10.10.10.10` y `10.10.10.30`, en solo lectura y con `root_squash`.
  Solo NFSv4 (puerto 2049).
- En `web` y `php` el montaje queda en el `/etc/fstab`. El `config.php` es `root:www-data 0640`, así que
  solo lo lee PHP-FPM (root de los clientes no puede por el `root_squash`).

## Requisitos

- libvirt/KVM, OpenTofu y Ansible (con las colecciones `community.mysql`, `community.general` y `ansible.posix`).
- Las imágenes base en el pool `default`: `debian13-base.qcow2` y `ubuntu2604-base.qcow2`
  (se pueden cambiar con las variables `imagen_base_debian` e `imagen_base_ubuntu`).
- Una clave ssh en `~/.ssh/id_rsa.pub` (variable `clave_ssh`).

## Despliegue

```bash
cd opentofu
tofu init        # solo la primera vez
tofu apply
cd ../ansible
ansible-playbook site.yaml
```

`tofu apply` genera el inventario `ansible/hosts` con los grupos `servidores_web`,
`servidores_php`, `servidores_bd` y `servidores_nas`.

Para acceder a la aplicación desde el equipo hay que resolver el nombre del virtual host:

```bash
echo "192.168.130.10 www.davidpefierro.org" | sudo tee -a /etc/hosts
```

y abrir <http://www.davidpefierro.org>.

Para destruir el escenario:

```bash
cd opentofu
tofu destroy
```

## Estructura

```
opentofu/
  provider.tf, variables.tf, network.tf, main.tf, output.tf
  inventario.tf, inventario.tftpl      # genera ../ansible/hosts
  cloud-init/                          # plantillas de user-data y network-config
ansible/
  ansible.cfg, site.yaml
  group_vars/                          # all y uno por grupo
  roles/commons                        # actualiza e instala paquetes comunes
  roles/bd                             # MariaDB, base de datos, usuario y tablas
  roles/nas                            # disco de datos, NFS, la aplicación y su config.php
  roles/cliente_nfs                    # monta la aplicación del nas (web y php)
  roles/php                            # PHP-FPM escuchando en la red de datos
  roles/web                            # Apache con proxy_fcgi y el virtual host
```

## Idempotencia

- `schema.sql` solo se importa si la tabla `messages` no existe todavía.
- El repositorio de la aplicación se clona con `update: false`, porque `config.php` (que está
  versionado en la aplicación) se sobrescribe con una plantilla.
- El disco de datos del `nas` solo se formatea si no tiene sistema de ficheros.
- Una segunda ejecución de `ansible-playbook site.yaml` termina con `changed=0`.
