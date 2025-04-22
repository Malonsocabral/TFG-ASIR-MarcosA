# Manual Técnico - Infraestructura IT para PYMES  
*Última actualización: 22/04/2025 

## 1. Requisitos del Sistema  
### 1.1 Hardware Mínimo  
| Componente       | Especificación                     |
|------------------|------------------------------------|
| CPU              | 4 núcleos con virtualización (VT-x/AMD-V) |
| RAM              | 8 GB (4 GB para pfSense)           |
| Almacenamiento   | 50 GB (SSD recomendado)            |

### 1.2 Software Requerido  
- **VirtualBox 7.0+** ([Descarga](https://www.virtualbox.org/))  
- **ISOs**:  
  - pfSense CE ([Descarga](https://www.pfsense.org/download/))  
  - Ubuntu Server 22.04 LTS ([Descarga](https://ubuntu.com/download/server))  

---

## 2. Diseño de la Red  
### 2.1 Diagrama de Arquitectura  
![Diagrama de Red](diagrama_red.png)  
*Leyenda*:  
- **VLAN Oficina (192.168.2.0/24)**: Equipos de usuarios.  
- **VLAN Servidores (192.168.1.0/24)**: Servicios críticos.  

### 2.2 Configuración de pfSense  
#### Firewall Rules (OPT1 → LAN):  
| Protocolo | Origen           | Destino         | Puerto | Acción | Descripción               |
|-----------|------------------|-----------------|--------|--------|---------------------------|
| TCP       | 192.168.2.0/24   | 192.168.1.2     | 80     | PASS   | Acceso HTTP a Nextcloud   |
| TCP       | 192.168.2.0/24   | 192.168.1.2     | 443    | PASS   | Acceso HTTPS              |

---

## 3. Automatización con Ansible  
### 3.1 Estructura del Playbook  
```---
- name: Despliegue completo de Nextcloud con LDAP y mejoras
  hosts: localhost
  connection: local
  become: true

  vars:
    nextcloud_admin_user: admin
    nextcloud_admin_password: admin123
    db_root_password: rootpass
    db_user: nextcloud
    db_password: nextcloudpass
    db_name: nextclouddb
    ldap_admin_password: adminldap
    ldap_domain: "dc=marcos,dc=tfg"

  tasks:
    # 1. Instalar dependencias necesarias del sistema
    - name: Instalar Docker y pip3
      apt:
        name: [docker.io, python3-pip]
        state: present
        update_cache: yes

    # 2. Instalar SDK de Docker para Python
    - name: Instalar módulo Docker para Python
      pip:
        name: docker
        executable: pip3

    # 3. Crear volúmenes Docker persistentes
    - name: Crear volumen para MariaDB
      docker_volume:
        name: mariadb_data

    - name: Crear volumen para Nextcloud
      docker_volume:
        name: nextcloud_data

    - name: Crear volumen para LDAP data
      docker_volume:
        name: ldap_data

    - name: Crear volumen para LDAP config
      docker_volume:
        name: ldap_config

    # 4. Crear red personalizada para que los contenedores se comuniquen
    - name: Crear red Docker
      docker_network:
        name: nextcloud_net

    # 5. Desplegar contenedor de MariaDB con volumen persistente
    - name: Desplegar base de datos MariaDB
      docker_container:
        name: mariadb
        image: mariadb:10.5
        restart_policy: unless-stopped
        networks:
          - name: nextcloud_net
        env:
          MYSQL_ROOT_PASSWORD: "{{ db_root_password }}"
          MYSQL_DATABASE: "{{ db_name }}"
          MYSQL_USER: "{{ db_user }}"
          MYSQL_PASSWORD: "{{ db_password }}"
        volumes:
          - mariadb_data:/var/lib/mysql
        healthcheck:
          test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
          interval: 10s
          retries: 5

    # 6. Desplegar contenedor LDAP
    - name: Desplegar OpenLDAP
      docker_container:
        name: openldap
        image: osixia/openldap:1.5.0
        restart_policy: unless-stopped
        networks:
          - name: nextcloud_net
        env:
          LDAP_ORGANISATION: "Marcos Org"
          LDAP_DOMAIN: "marcos.tfg"
          LDAP_ADMIN_PASSWORD: "{{ ldap_admin_password }}"
        volumes:
          - ldap_data:/var/lib/ldap
          - ldap_config:/etc/ldap/slapd.d

    # 7. Desplegar Nextcloud
    - name: Desplegar Nextcloud
      docker_container:
        name: nextcloud
        image: nextcloud
        restart_policy: unless-stopped
        ports:
          - "8080:80"
        networks:
          - name: nextcloud_net
        volumes:
          - nextcloud_data:/var/www/html
        env:
          MYSQL_HOST: mariadb
          MYSQL_DATABASE: "{{ db_name }}"
          MYSQL_USER: "{{ db_user }}"
          MYSQL_PASSWORD: "{{ db_password }}"
          NEXTCLOUD_ADMIN_USER: "{{ nextcloud_admin_user }}"
          NEXTCLOUD_ADMIN_PASSWORD: "{{ nextcloud_admin_password }}"```
