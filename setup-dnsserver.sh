##!/bin/sh

# https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-private-network-dns-server-on-ubuntu-18-04-es

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
sudo apt install bind9 bind9utils bind9-doc
systemctl status bind9                          # o también por 'named'

# EDITAR opciones del servidor, guardando el fichero instalado por defecto
sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.default
tee /etc/bind/named.conf.options < 'CONTENIDO'
acl LANS { 192.168.1.0/24; 192.168.2.0/24; };

options {
  directory "/var/cache/bind";
  allow-query { localhost; localnets; LANS; };  # o 'any' para consultas autoritativas
  recursion yes;
  forwarders { 1.1.1.1; };
# si solo se desea escuchar en un interface (NIC), p.e enp0s8 (192.168.1.1)
#  listen-on { 192.168.1.1; };
# si solo permitir el uso del dns internamente:
#  allow-recursion { LANS; };
#  allow-query-cache { LANS; };
};
CONTENIDO

sudo named-checkconf /etc/bind/named.conf.options   # comprobar sintáxis
sudo systemctl restart named                        # aplicar cambios


# (4) Configurar cliente linux desde consola: En [SWEB] (ver _setup-lab-network)
# obtener la NIC
ip -brief addr show to 192.168.1.0/24        # o abrevia con 'ip a' y busca
# editar NETPLAN /etc/netplan/*.yaml
# Nota: Si la configuración es con 'network', ver ejemplo en _setup-lab-network
sudo nano /etc/netplan/<file>.yaml
: << 'CONTENIDO'
Se añadirá al fichero, dentro de la sección network: - ethernets: - <nic_name>:
  nameservers:
    addresses: [ 10.0.2.1, 8.8.4.4 ]    # ip del servidor dns [R]
    search [ midominio.example ]        # si se configuró una zona en el servidor dns
CONTENIDO
# Editando directamente el fichero, aplica al guardarlo
# Si se edita netplan con comandos CLI:
sudo netplan try            # comprobar y aplicar cambios o revertir (timeout)
#sudo netplan -debug apply  # aplicar configuración por CLI
netplan status              # comprobar config y "online status:" Si estuviera offline, ejecutar sudo netplan apply y volver a comprobar
# comprobar estado de red actual:
ip addr

: << 'COMMENT'
Cuando se hace una consulta dns domain.ext, si se usa netplan, 
primero pasa por el resolver systemd-resolved (con un stub listener), 
configurado en /run/systemd/resolve/stub-resolv.conf, 
que afecta a /etc/systemd/resolve/resolv.conf,
que devolverá resultado cacheado 
o lo pasará a los nameservers configurados en netplan NIC
systemd-resolve --status nos muestra la lista de upstream DNS servers
Comprobar también si está instalado resolvconf (systemctl status resolvconf), desactivarlo.
O deshabilitar systemd-resolved y crear manualmente /etc/resolv.conf
(que es sobreescrito por systemd-resolved, por lo que los cambios son temporales)
++ Cambios via resolve.conf
Para config permanentes, editar /etc/systemd/resolve/resolv.conf o /etc/systemd/resolved.conf
DNS=<ip> <ip>      # primarios
FallbackDNS=<ip>   #
y systemctl restart systemd-resolved
check: resolvectl status  # de cada ethernet

++ cambios vía netplan (config nameservers)
Modificar el yaml con nameservers -addresses para las NIC

** Se puede desactivar el stub listener, y liberar el puerto 53 para el dns server, 
editando /etc/system/resolve/resolv.conf DNSStubListener=no
netplan try y posiblemente reiniciar el servidor con sudo reboot.
COMMENT

# CONFIGURAR FIREWALL para permitir in a 53 UDP. Ver fichero setup-firewall.txt

# CREAR ZONA 
sudo nano /etc/bind/named.conf.local
: << 'CONTENIDO'
zone "dominio.example" {
  type master;
  file "/etc/bind/zones/db.

}
CONTENIDO

# comprobar configuración de zona dns midominio.example, por nombre y por fqdn
# desde [R] y desde otro cliente en LANS
nslookup sweb
nslookup sweb.midominio.example
ping sweb









