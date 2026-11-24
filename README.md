```markdown
# Administración de WordPress con WP-CLI

Documento técnico y scripts de automatización para la instalación, configuración y administración de **WordPress** mediante la utilidad **WP-CLI** sobre una instancia **AWS EC2 (Ubuntu)** con pila **LAMP** y certificado **SSL/TLS de Let's Encrypt**.

---

## 1. Estructura del repositorio

```text
.
├── README.md
├── conf
│   └── 000-default.conf
├── htaccess
│   └── .htaccess
└── scripts
    ├── .env
    ├── install_lamp.sh
    ├── setup_letsencrypt_https.sh
    └── deploy_wordpress_with_wpcli.sh

```

* **`README.md`**: Documentación técnica del despliegue e instalación con WP-CLI.
* **`conf/000-default.conf`**: Configuración del `VirtualHost` de Apache con `AllowOverride All` para soportar `.htaccess`.
* **`htaccess/.htaccess`**: Reglas de reescritura de URLs limpias (enlaces permanentes) de WordPress.
* **`scripts/.env`**: Variables de entorno empleadas por los scripts de Bash.
* **`scripts/install_lamp.sh`**: Automatiza la instalación de Apache, MariaDB y PHP.
* **`scripts/deploy_wordpress_with_wpcli.sh`**: Automatiza la instalación de WordPress sobre `/var/www/html` con `wp-cli`.
* **`scripts/setup_letsencrypt_https.sh`**: Automatiza la obtención y configuración del certificado SSL/TLS de Let's Encrypt en Apache.

---

## 2. Entorno de despliegue y variables de configuración

* **Infraestructura:** Instancia AWS EC2 con Ubuntu (`172.31.32.178`) e IP elástica `54.163.100.57`.
* **Nombre de dominio:** `practica-xiomi.ddns.net` (registro DNS tipo `A` configurado en No-IP apuntando a `54.163.100.57`).
* **Grupo de seguridad (AWS):** Puertos abiertos `22` (SSH), `80` (HTTP) y `443` (HTTPS).
* **Variables de configuración (`scripts/.env`):**
* `DB_NAME`, `DB_USER`, `DB_PASSWORD`: Nombre, usuario y contraseña de la base de datos en MariaDB.
* `WP_URL`, `WP_TITLE`, `WP_ADMIN_USER`, `WP_ADMIN_PASSWORD`, `WP_ADMIN_EMAIL`, `WP_LOCALE`: Parámetros de instalación de WordPress.
* `DOMAIN`, `CERTBOT_EMAIL`: Dominio y correo electrónico para solicitar el certificado SSL/TLS con Certbot.



---

## 3. Descripción del proceso de instalación de WordPress con WP-CLI

La instalación y configuración de WordPress en el directorio raíz `/var/www/html` se realizó mediante la herramienta de línea de comandos **WP-CLI** siguiendo estos pasos:

### Paso 1. Instalación de WP-CLI

Se descarga el archivo `wp-cli.phar` oficial, se le otorgan permisos de ejecución y se ubica en `/usr/local/bin/wp` para poder ejecutar el comando `wp` desde cualquier ruta del sistema:

```bash
curl -fsSL [https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar](https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar) -o /tmp/wp-cli.phar
chmod +x /tmp/wp-cli.phar
mv /tmp/wp-cli.phar /usr/local/bin/wp
wp --info

```

### Paso 2. Preparación del directorio raíz y descarga de WordPress

Se limpia el contenido previo de `/var/www/html` y se descarga el núcleo de WordPress en español (`es_ES`) directamente sobre `/var/www/html`:

```bash
rm -rf /var/www/html/*
wp core download --locale=es_ES --path=/var/www/html --allow-root

```

### Paso 3. Creación de la base de datos y el usuario en MariaDB

Se crea la base de datos con soporte Unicode (`utf8mb4`) y un usuario dedicado con todos los privilegios sobre ella:

```sql
CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'password_segura';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;

```

### Paso 4. Generación del archivo de configuración `wp-config.php`

Se genera automáticamente `wp-config.php` vinculando WordPress con la base de datos y credenciales creadas en MariaDB:

```bash
wp config create \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASSWORD" \
    --dbhost="localhost" \
    --path=/var/www/html \
    --allow-root

```

### Paso 5. Instalación de WordPress y creación del administrador

Se crean las tablas de la base de datos y se inicializa el sitio web con la URL del dominio, el título y el usuario administrador:

```bash
wp core install \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --path=/var/www/html \
    --allow-root

```

### Paso 6. Configuración de `.htaccess` y permisos de Apache

Se copia el archivo `.htaccess` en `/var/www/html/.htaccess` para habilitar los enlaces permanentes mediante `mod_rewrite` y se asigna la propiedad de `/var/www/html` al usuario `www-data`:

```bash
cp ../htaccess/.htaccess /var/www/html/.htaccess
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

```

---

## 4. Automatización mediante scripts de Bash

Para reproducir todo el despliegue de forma automática en una instancia limpia de Ubuntu:

1. **Conceder permisos de ejecución a los scripts:**
```bash
cd scripts
chmod +x install_lamp.sh deploy_wordpress_with_wpcli.sh setup_letsencrypt_https.sh

```


2. **Instalar la pila LAMP y configurar Apache:**
```bash
sudo ./install_lamp.sh

```


3. **Desplegar WordPress con WP-CLI:**
```bash
sudo ./deploy_wordpress_with_wpcli.sh

```


4. **Configurar HTTPS con Let's Encrypt:**
```bash
sudo ./setup_letsencrypt_https.sh

```



---

## 5. Administración y verificación de WordPress con WP-CLI

Tras la instalación, se realizaron tareas de gestión y comprobación desde consola en `/var/www/html`:

* **Verificación del núcleo:** `wp core version --path=/var/www/html --allow-root` y `wp core check-update`.
* **Gestión de temas:** `wp theme list`, instalación y activación de temas mediante `wp theme install` / `wp theme activate`.
* **Gestión de plugins:** `wp plugin list`, instalación, activación y actualización de plugins mediante `wp plugin install` / `wp plugin activate`.
* **Registro de sesión:** Captura de la sesión de trabajo en terminal y limpieza de secuencias de escape con `col -b`.

```

```


