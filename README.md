# Proyecto 1: Infraestructura como código

Escenario con OpenTofu (libvirt/KVM) configurado con Ansible para poner en producción
el libro de visitas [guestbook_php](https://github.com/josedom24/guestbook_php) con MariaDB.

## Escenario

| Máquina | Sistema       | Red NAT (DHCP)   | Red de datos  | Función             |
|---------|---------------|------------------|---------------|---------------------|
| `web`   | Debian 13     | 192.168.130.10   | 10.10.10.10   | Apache (sin PHP)    |
| `php`   | Debian 13     | 192.168.130.30   | 10.10.10.30   | PHP-FPM             |
| `bd`    | Ubuntu 26.04  | 192.168.130.20   | 10.10.10.20   | MariaDB             |

- **p1-nat** (`192.168.130.0/24`): red NAT con DHCP. Las IP se reservan por MAC para que no
  cambien al recrear el escenario. Por aquí se accede a la web y entra Ansible.
- **p1-datos** (`10.10.10.0/24`): red muy aislada (sin DHCP ni salida), con IP estáticas
  puestas por cloud-init. Por ella Apache pasa los `.php` a PHP-FPM y PHP-FPM se conecta a MariaDB.

### PHP-FPM en otra máquina (modificación 1)

Apache no ejecuta PHP: los ficheros `.php` se mandan con `mod_proxy_fcgi` a PHP-FPM, que escucha en
`10.10.10.30:9000` y solo acepta conexiones de `web`. La aplicación está desplegada en las dos máquinas
en la misma ruta (`/var/www/guestbook`): Apache la necesita para los estáticos y el `.htaccess`, y PHP-FPM
para ejecutar los ficheros que le indica Apache. El `config.php` con la contraseña solo está en `php`, que
es la única máquina que se conecta a la base de datos (el usuario de MariaDB solo puede entrar desde ahí).

## Requisitos

- libvirt/KVM, OpenTofu y Ansible (con las colecciones `community.mysql` y `community.general`).
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
`servidores_php` y `servidores_bd`.

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
  group_vars/                          # all, servidores_web, servidores_php, servidores_bd
  roles/commons                        # actualiza e instala paquetes comunes
  roles/bd                             # MariaDB, base de datos, usuario y tablas
  roles/php                            # PHP-FPM, la aplicación y su config.php
  roles/web                            # Apache con proxy_fcgi, virtual host y la aplicación
```

## Idempotencia

- `schema.sql` solo se importa si la tabla `messages` no existe todavía.
- El repositorio de la aplicación se clona con `update: false`, porque `config.php` (que está
  versionado en la aplicación) se sobrescribe con una plantilla.
- Una segunda ejecución de `ansible-playbook site.yaml` termina con `changed=0`.
