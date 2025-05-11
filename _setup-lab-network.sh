##!\bin\sh

# =============================================================
# CONFIGURACIÓN DEL LABORATORIO PARA PROBAR LAS FUNCIONALIDADES
# =============================================================
: << 'COMMENT'
[R]     Ubuntu 24.04 server LTS
  enp0s3  10.0.2.0/24 dhcp  vbox: NAT
  enp0s8  192.168.1.1/24  vbox: INTERNAL NETWORK name: LAN1,  advanced, Promiscuous Mode: Allow All
  enp0s9  192.168.2.1/24  vbox: INTERNAL NETWORK name: LAN2,  advanced, Promiscuous Mode: Allow All
[SWEB]  Ubuntu 24.04 server LTS
  enp0s3  192.168.1.2/24  vbox: INTERNAL NETWORK name: LAN1,  advanced, Promiscuous Mode: Allow All
[PC10]  Ubuntu 24.04 desktop LTS
  enp0s3  192.168.1.10/24 vbox: INTERNAL NETWORK name: LAN1,  advanced, Promiscuous Mode: Allow All
[PC20]  Windows 11
  Red    192.168.2.10/24  vbox: INTERNAL NETWORK name: LAN2,  advanced, Promiscuous Mode: Allow All

R será el FW y el proveedor de Internet (router)
Para enrutado entre subredes, en equipos Windows, abrir en FW:
- Supervisión de máquina virtual (solicitud de eco - ICMPv4 de entrada) Todos             ON
- Archivos e impresoras compartidos (petición eco: ICMPv4 de entrada)   Privado, Público  ON
COMMENT

# CONFIGURAR INTERFACES DE RED DE CLIENTES DE LAN
# ===============================================
# PC10 (Ubuntu desktop): 192.168.1.10/24, 192.168.1.1 GW, 8.8.8.8 DNS
# PC20 (Windows):        192.168.1.20/24, 192.168.2.1 GW, 8.8.8.8 DNS

# CONFIGURAR INTEFACES DE RED DE R (Ubuntu server)
# ================================
# Documentación netplan: https://netplan.readthedocs.io/en/stable/
# CONFIGURAR RED DE R. Según se use (a) netplan o (b) network interfaces
# (A) Con Netplan. Crear /etc/netplan/config.yaml
tee > /etc/netplan/config.yaml << 'EOF'
network:
  renderer: networkd
  version: 2
  ethernets:
    enp0s3:
      dhcp: true
    enp8s0: 
      addresses: [192.168.1.1/24]
    enp9s0:
      addresses: [192.168.2.1/24]
EOF
# Editando directamente el fichero, aplica al guardarlo
# Si se edita netplan con comandos CLI:
sudo netplan try    # aplica con cuenta atrás para revertir a config anterior, o enter para aplicar definitivamente
sudo netplan apply  # aplicar configuración por CLI
netplan status      # comprobar config y "online status:" Si estuviera offline, ejecutar sudo netplan apply y volver a comprobar
# comprobar estado de red actual:
ip addr

# (B) Con network. Añadir ficheros por cada NIC en /etc/network/interfaces.d/
tee > /etc/network/interfaces.d/ enp0s3.conf << 'NIC'
auto enp0s3
iface enp0s3 inet dhcp
NIC
tee > /etc/network/interfaces.d/ enp0s8.conf << 'NIC'
auto enp0s8
iface enp0s8 inet static
address 192.168.1.1/24
mtu 1500
NIC
tee > /etc/network/interfaces.d/ enp0s9.conf << 'NIC'
auto enp0s9
iface enp0s9 inet static
address 192.168.2.1/24
mtu 1500
NIC
# Aplicar la nueva configuración de red:
sudo systemctl restart networking
# comprobar configuración actual
ip a     # o la antigua ifconfig -a

# ESTABLECER ENRUTADO ENTRE LAS SUBREDES LAN1 Y LAN2. En R
# ========================================================
# Permite conectar entre las LAN
# comprobar estado de ipv4 forwarding (routing)
sysctl net.ipv4.ip_forward
#sudo sysctl -w net.ipv4.ip_forward=1  # no modifica /etc/sysctl.conf. Solo durante la sesión
: << 'EDITAR_FICHERO'
/etc/sysctl.conf
Descomentar o crear net.ipv4.ip_forward=1
guardar
# para aplicar los cambios de sysctl.conf y hacer el routing permanente
sysctl -p
EDITAR_FICHERO
ip route    # mostrar enrutado actual
# IMPORTANTE: En cada cliente, hay que configurar como GW la ip asignada en la NIC de R asociada a su LANx

# COMPROBAR CONECTIVIDAD ENTRE LANs
ping 192.168.2.1     # desde PC10 al GW de LAN2
ping 192.168.2.10    # desde PC10 a PC20
ping 192.168.1.1     # desde PC20 al GW de LAN1
ping 192.168.1.10    # desde PC20 a PC10
# Si no se llega a Windows (PC20) 
# Comprobar que se permite ping entrante en Windows (ver COMMENT inicial)
# Si aún no llega, desactivar FW en perfil público y luego el privado.
# Si ya funciona, hay un regla entrante que bloquea

# CONFIGURAR ACCESO A INTERNET PARA LAS LAN a través de R
# =========================================
# Qué fw está activo? en Ubuntu 20.04+, iptables a través de ufw (frontend)
# Se puede config iptables directam o a través de ufw
update-alternatives --query iptables

# reset FW:
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
# configurar acceso a internet de las subredes
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o enp0s9 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i enp0s9 -o enp0s3 -j ACCEPT

# Persistir la configuración entre inicios. Se usará el paquete iptables-persistent
# Si está instalado el paquete, existirá /etc/iptables/
sudo apt install iptables-persistent
# Guardar la configuración actual iptables
sudo iptables-save > /etc/iptables/rules.v4
# si el anterior comando genera error de permisos, usar 
sudo bash -c "iptables-save > /etc/iptables/rules.v4 "
# o el siguiente para crear el fichero v4
sudo dpkg-reconfigure iptables-persistent






