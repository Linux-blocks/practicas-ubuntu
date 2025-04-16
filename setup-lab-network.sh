##!\bin\sh

# =============================================================
# CONFIGURACIÓN DEL LABORATORIO PARA PROBAR LAS FUNCIONALIDADES
# =============================================================
: << 'COMMENT'
VirtualBox: Crear subredes net_192.168.1, net_192.168.2 con dhcp desactivado.

[R]     Ubuntu 24.04 server LTS
  enp0s3  10.2 dhcp       vbox: NAT
  enp0s8  192.168.1.1/24  vbox: INTERNAL NETWORK name: LAN1,  advanced, Promiscuous Mode: Allow All
  enp0s9  192.168.2.1/24  vbox: INTERNAL NETWORK name: LAN2,  advanced, Promiscuous Mode: Allow All
[SWEB]  Ubuntu 24.04 server LTS
  enp0s3  192.168.1.2/24  vbox: INTERNAL NETWORK name: LAN1,  advanced, Promiscuous Mode: Allow All
[PC10]  Ubuntu 24.04 desktop LTS
  enp0s3  192.168.1.10/24 vbox: INTERNAL NETWORK name: LAN1,  advanced, Promiscuous Mode: Allow All
[PC20]  Windows 11
  Red    192.168.2.10/24  vbox: INTERNAL NETWORK name: LAN2,  advanced, Promiscuous Mode: Allow All

Nota: En Windows, habilitar en FW entrada: Archivos e impresoras compartidos (petición eco: ICMP4) perfiles privado y público
R será el FW y el proveedor de Internet (router)
COMMENT

# Documentación netplan: https://netplan.readthedocs.io/en/stable/
# Netplan R. Crear /etc/netplan/config.yaml
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
# comprobar errores en netplan. Aplica temporalmente las modificaciones realizadas o revierte
netplan try
netplan status    # comprobar config y "online status:" Si estuviera offline, ejecutar sudo netplan applu y volver a comprobar
# aplicar netplan? en mi test tras guardar el yaml ha aplicado y se ha mantenido tras reiniciar. 
# Parece que si se edita directamente el yaml y guarda, aplica autom. Pero aquí está la opción ...
sudo netplan apply
# aplica una vez guardado. Pero comprobar con
ip addr

# ESTABLECER ENRUTADO ENTRE LAS SUBREDES LAN1 Y LAN2. En R.
# Permite conectar entre las LAN y estas acceder a Internet, según reglas FW cadena FORWARD
# comprobar estado de ipv4 forwarding (routing)
sysctl net.ipv4.ip_forward
#sudo sysctl -w net.ipv4.ip_forward=1  # no modifica /etc/sysctl.conf. Solo durante la sesión
: << 'EDITAR_FICHERO'
/etc/sysctl.conf
Descomentar o crear net.ipv4.ip_forward=1
guardar
# para aplicar lo cambios de sysctl.conf y hacer el routing permanente
sysctl -p
EDITAR_FICHERO
ip route    # mostrar enrutado actual
# IMPORTANTE: En cada cliente, hay que configurar como GW la ip asignada en la NIC asociada a la LANx

# COMPROBAR CONECTIVIDAD ENTRE LANs
ping 192.168.2.1     # desde PC10 al GW de LAN2
ping 192.168.2.10    # desde PC10 a PC20
ping 192.168.1.1     # desde PC20 al GW de LAN1
ping 192.168.1.10    # desde PC20 a PC10    # si no alcanza, comprobar que se permite ping entrante en Windows

# CONFIGURAR ACCESO A INTERNET PARA LAS LAN
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







