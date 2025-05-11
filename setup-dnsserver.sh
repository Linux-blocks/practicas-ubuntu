#!/bin/sh

: << COMMENT
En el servidor [R] (Ubuntu server 24 LTS)
  (1) enp0s3: Cambiar a estática 10.0.2.1/24 (ip en el rango NAT de vbox)
      Las otras 2 NIC como en el fichero _setup-lab-network
  (2) Instalar bind9 
  (3) Configurar Bind9
  (4) Configurar cliente Linux (opción modo texto)
COMMENT

# INSTALAR SERVIDOR DNS (bind9)
sudo apt update
sudo apt list | grep bind9
sudo apt install bind9 bind9utils bind9-doc
# comprobar estado del servicio
systemctl status bind9  # o también por 'named'

# EDITAR opciones del servidor, guardando el fichero instalado por defecto
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.default
tee > /etc/bind/named.conf.options < 'EOF'
acl LANS { 192.168.1.0/24; 192.168.2.0/24; }

options {
  directory "/var/cache/bind";
  allow-query { localhost; localnets; LANS; };  # o 'any' para consultas autoritativas
  recursion yes;
  forwarders { 1.1.1.1; };
# si solo se desea escuchar en un interface (NIC), p.e enp0s8 (192.168.1.1)
#  listen-on { 192.168.1.1 };
# si solo permitir el uso del dns internamente:
#  allow-recursion { LANS; };
#  allow-query-cache { LANS; };
};
EOF
# comprobar sintáxis. Si ok no devuelve nada
sudo named-checkconf /etc/bind/named.conf.options
# aplicar cambios
sudo systemctl restart named

# (4) Configurar cliente linux desde consola: En [SWEB] (ver _setup-lab-network)
# obtener la NIC
ip -brief addr show to 192.168.1.0/24  # o abrevia con 'ip a' y busca
# editar NETPLAN /etc/netplan/*.yaml
# Nota: Si la configuración es con 'network', ver ejemplo en _setup-lab-network
: << 'COMMENT'
Se añadirá al fichero, dentro de la sección network: - ethernets: - <nic_name>:
  nameservers:
    addresses: [ 10.0.2.1 ]       # ip del servidor dns [R]
    search [ midominio.example ]  # si se configuró una zona en el servidor dns
COMMENT
# Editando directamente el fichero, aplica al guardarlo
# Si se edita netplan con comandos CLI:
sudo netplan try    # aplica con cuenta atrás para revertir a config anterior, o enter para aplicar definitivamente
sudo netplan apply  # aplicar configuración por CLI
netplan status      # comprobar config y "online status:" Si estuviera offline, ejecutar sudo netplan apply y volver a comprobar
# comprobar estado de red actual:
ip addr

# comprobar configuración de zona dns midominio.example, por nombre y por fqdn
# desde [R] y desde otro cliente en LANS
nslookup sweb
nslookup sweb.midominio.example
ping sweb









