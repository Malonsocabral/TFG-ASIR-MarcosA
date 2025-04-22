# Checklist de Seguridad - Infraestructura PYMES

## 1. pfSense (Firewall)
- [x] Cambiar credenciales predeterminadas (`admin/pfsense` → contraseña compleja)
- [x] Habilitar **Block Bogon Networks** (Firewall > Settings)
- [x] Configurar reglas anti-spoofing:
  ```
  # Regla: Bloquear tráfico WAN con IP origen = LAN
  ```
- [x] Actualizar a la última versión estable (System > Update)

## 2. Servidor Ubuntu

### 2.1 Sistema Base
- [ ] Ejecutar hardening con:
  ```
  sudo apt install unattended-upgrades
  sudo dpkg-reconfigure --priority=low unattended-upgrades
  ```
- [ ] Deshabilitar SSH root:
  ```
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config
  ```

### 2.2 Docker
- [ ] Restringir permisos:
  ```
  sudo chmod 600 /var/run/docker.sock
  ```
- [ ] Escanear imágenes con Trivy:
  ```
  trivy image nextcloud:latest
  ```

## 3. Servicios

### 3.1 Nextcloud
- [ ] Habilitar 2FA (Ajustes > Seguridad)
- [ ] Configurar cifrado de datos:
  ```
  sudo -u www-data php occ encryption:enable
  ```

### 3.2 LDAP
- [ ] Forzar conexiones TLS:
  ```
  docker run --env LDAP_TLS=true osixia/openldap
  ```

## 4. Monitorización
- [ ] Alertas en Grafana para:
  - Intentos de login fallidos > 5/min
  - Uso CPU > 90% por 5 min
