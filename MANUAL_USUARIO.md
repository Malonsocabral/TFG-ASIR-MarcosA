## 1. Acceso a Servicios  
| Servicio       | URL                          | Credenciales               |
|----------------|------------------------------|----------------------------|
| Nextcloud      | `http://192.168.1.2:8080`    | admin / admin123           |
| pfSense        | `https://192.168.1.1`        | admin / pfsense            |

## 2. Gestión de Usuarios  
### 2.1 Añadir Usuario LDAP  
1. Conectarse al servidor Ubuntu:
```ssh admin@192.168.1.2 ```
2. Ejecutar un comando tal que asi:
```
docker exec -i openldap ldapadd -x -D "cn=admin,dc=example,dc=com" -w adminldap <<EOF
dn: uid=nuevo,dc=example,dc=com
objectClass: inetOrgPerson
uid: nuevo
sn: Apellido
cn: Nombre
userPassword: claveSegura123
EOF
```
## 3. Backups
### 3.1 Ejecución Manual
```
sudo /opt/scripts/backup.sh
```
*Almacena backups en /mnt/backups con cifrado AES-256*

### 3.2 Restauración
Listar backups disponibles:
```
borg list /mnt/backups
```
Extraer un backup:

```
borg extract /mnt/backups::nextcloud-2023-11-20
```
