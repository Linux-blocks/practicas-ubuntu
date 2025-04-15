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

# Netplan R. Crear /etc/netplan/config.yaml
tee > /etc/netplan/config.yaml << 'EOF'
network:
  renderer: 
  version: 2
  ethernets:
    enp0s3:
      dhcp: true
    enp8s0: 
      addresses: [192.16.8.1.1/24]
    enp9s0:
      addreses: [192.168.2.1/24]
EOF
