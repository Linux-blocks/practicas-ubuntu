#! /bib/sh
: << COMMENT
En el servidor [SWEB]:
  (1) Instalar servidor y configurar sitio web default.
  (2) Solo permitir acceso al servidor web al equipo [PC20: 192.168.2.10].
COMMENT

# (1) Instalar servidor y configurar un sitio web
#INSTALAR APACHE2
apt update
# apt list --installed  lista instalados
# El pack listado contiene: [installed, 
apt list | grep apache
# Si no está instalado, hacerlo
sudo apt install apache2
# Comprobar en localhost el funcionamiento del web server: Navega a 127.0.0.1 (sitio default).

# CREAR Y CONFIGURAR UN SITIO WEB
# Crear carpetas y ficheros para el sitio test-site, y configurar los permisos.
# crear carpeta e intermedias (-p)
sudo mkdir -p /var/www/test-site/html
# Cambiar propietario y grupo al del usuario actual
sudo chown -R $USER:$USER /var/www/test-site
# Asegurar rx en la raíz de sitios para que propietarios no root lleguen
# (es posible que no sea necesario)
sudo chmod -R 755 /var/www

# Crear la página default para el test-site:
# bien intereactivamente: nano /var/www/test-site/html/index.html
# bien con scripting:
cat > "/var/www/test-site/html/index.html" << 'EOF'
<html><head></head><body>
<h1 style="text-align:center;"> TEST-SITE </h1><br />
<p>Este sitio ha sido creado como ejercicio</p>
<p style="color:red;text-align:center;"> El sitio FUNCIONA</p>
</body></html>
EOF

# CREAR Y ACTIVAR EL VIRTUAL HOST DEL SITIO
cd /etc/apache2/sites-available
sudo cp 000-default.conf test-site.conf 
# crear bien interactivamente: sudo nano test-site.conf
# bien con scripting: 
sudo tee > "test-site.conf" << 'EOF' > /dev/null
DocumentRoot /var/www/test-site/html
ServerName test-site.com
EOF
# Habilitar el sitio (publicarlo)
sudo a2ensite test-site
# Recargar config apache2 para aplicar
sudo systemctl reload apache2

# Deshabilitar el sitio default hace que antes petición http desconocida muestre el primer vhost
# (el primer fichero config en sites-available)
sudo a2dissite 000-default

# (2) RESTRINGIR ACCESOS WEB AL SITIO: Solo a PC20
# FW: Acceso web solo desde PC20
iptables -A INPUT -p tcp -m multiport --dports 80,443 -s 192.168.2.10 -j ACCEPT

