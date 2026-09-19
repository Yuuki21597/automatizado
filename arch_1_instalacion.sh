#!/usr/bin/env bash

# Sección 1: Cargado de datos sensibles.
AQUI="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
RAIZ="$(dirname "$AQUI")"
ENTORNO="$RAIZ/librerias/info.env"

if [[ -f "$ENTORNO" ]]; then
    source "$ENTORNO"
    echo "Variables de entorno cargadas desde: $ENTORNO"
else
    echo "Error: No se encontró el archivo .env en $ENTORNO" >&2
fi

# Sección 2: configuración de la consola.

# Configura la distribución del teclado.
loadkeys la-latin1

# Conecta el equipo a internet via WiFi.
iwctl adapter phy0 set-property Powered on
iwctl device wlan0 set-property Powered on
iwctl --passphrase "$contra_wifi" station wlan0 connect "$nombre_wifi"

# Confirmación de la conexión.
ping -c 3 archlinux.org
ping -c 3 www.google.com

echo "es_GT.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
export LANG=es_GT.UTF-8 # Coloca la consola de Arch en español

# Sección 3: formateo.

# Esta sección es más explicativa. Aunque es un script, en una instalación live, es en realidad engorroso montar una unidad y darle permisos al script para hacerlo correr.
lsblk # Se usa este comando para obtener una lista de todas las unidades conectadas y así hallar ¿el nombre? del dispositivo donde se instalará el sistema.
echo "Escribe la ruta del disco donde se instalará el sistema. PRECAUCIÓN: El disco indicado será BORRADO. No quedarán ni las particiones."
read DISCO_PRINCIPAL

# Una vez decidida la unidad a usar, se formatea:
sgdisk --zap-all "/dev/$DISCO_PRINCIPAL"
# Tras el borrado total de la unidad, se usa cfdisk con una interfaz de terminal para realizar el particionado del sistema.
cfdisk "/dev/$DISCO_PRINCIPAL"
lsblk # Finalmente se comprueba con lsblk que todo está en orden.

# Debido a que el modo de arranque varía entre BIOS y UEFI (aunque supongo que BIOS morirá con el pasar del tiempo), la partición booteable que inicia el sistema también se instala de forma diferente.
# Si no hay valor, es BIOS. Por eso:
# Por cierto, aquí "-d" sirve para verificar si un directorio existe.
if [ -d "/sys/firmware/efi" ]; then
  MODO_ARRANQUE="UEFI"
  BITS_UEFI=$(cat /sys/firmware/efi/fw_platform_size)
  echo "SISTEMA: UEFI de $BITS_UEFI bits detectado."
else
  MODO_ARRANQUE="BIOS"
  echo "SISTEMA: BIOS/Legacy detectado."
fi

echo "Escribe la ruta a la partición booteable."
read PARTICION_DE_INICIO

if [ "$MODO_ARRANQUE" == "BIOS" ]; then
  mkfs.ext4 -L "BIOS" "/dev/$PARTICION_DE_INICIO"
else
  mkfs.fat -F 32 -n "UEFI" "/dev/$PARTICION_DE_INICIO"
fi

# La particion swap sirve como respaldo de la memoria RAM al momento de hibernar el equipo, o como espacio extra en caso de que la memoria RAM se llene por completo debido a cualquier situación. No es del todo necesaria debido a que el sistema mismo puede crear archivos swap en caso de no exitir esta partición.
echo "Escribe la ruta a la particion SWAP. Si no la requieres, presiona enter."
read PARTICION_SWAP

# Por cierto, aquí "-n" sirve para comprobar una cadena (todas las variables en bash son cadenas). Si la cadena está vacía, devuelve false.
if [ -n "$PARTICION_SWAP" ]; then
  echo "Configurando SWAP en $PARTICION_SWAP..."
  mkswap "/dev/$PARTICION_SWAP"
  swapon "/dev/$PARTICION_SWAP"
else
  echo "No se especificó partición SWAP. Se omite este paso."
fi

# Finalmente se da formato a la partición raíz/root.
echo "Escribe la ruta a la particion root:"
read PARTICION_ROOT
echo "Escribe el nombre de la partición principal (root):"
read NOMBRE_DE_LA_PARTICION_ROOT
mkfs.ext4 -L "$NOMBRE_DE_LA_PARTICION_ROOT" "/dev/$PARTICION_ROOT"

# Sección 4: montaje.
# El sistema que se está creando se guarda en el directorio /mnt. ¿Por qué? Ni idea, no he averiguado. Lo que puedo suponer es que se le da el tratamiento de una unidad externa de forma que el sistema en live puede trabajar en el nuevo sistema mientras este aún no puede valerse por sí mismo.

mount "/dev/$PARTICION_ROOT" /mnt

if [ "$MODO_ARRANQUE" == "BIOS" ]; then
  mkdir -p /mnt/boot
  mount "/dev/$PARTICION_DE_INICIO" /mnt/boot/
else
  mkdir -p /mnt/boot/efi
  mount "/dev/$PARTICION_DE_INICIO" /mnt/boot/efi
fi

# Sección 5: instalación del sistema.
# Primero usamos reflector para asegurarnos que tendremos los repositorios más veloces en el nuevo sistema. ¿Qué debo hacerlo yo mismo? Podría y sería más engorroso y la experiencia me dicta que no estoy en un lugar geográfico privilegiado por las velocidades de internet si me dirijo a los repositorios geográficamente más cercanos. Mejor que las máquinas hagan lo que mejor saben hacer: calcular.
reflector --age 12 --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

# Aquí es donde empieza mi parte obsesiva con este asunto. La cantidad de paquetes en el sistema. Suena tonto, pero: ¿para qué tener aquello que no necesito? Esa es la razón por la que uso Arch Linux.
pacstrap -K /mnt base linux linux-firmware iwd nano fastfetch
# Este comando instala 157 paquetes. Están ordenados del más importante al más prescindible.
genfstab -p /mnt >> /mnt/etc/fstab

# Sección 6: configuración de red.
# "¡Configúralo o no tendras internet!"...
# " Puff, como si esas cosas pasaran xD
arch-chroot /mnt /bin/bash <<EOF
systemctl enable iwd
systemctl enable systemd-networkd
systemctl enable systemd-resolved
ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

cat <<EOT > /etc/systemd/network/20-wired.network
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes
EOT

cat <<EOT > /etc/systemd/network/25-wireless.network
[Match]
Name=wl*

[Network]
DHCP=yes
EOT
EOF

mkdir /mnt/tmp
cat <<EOF > /mnt/tmp/variables.sh
MODO_ARRANQUE="$MODO_ARRANQUE"
DISCO_PRINCIPAL="$DISCO_PRINCIPAL"
EOF

cp "$RAIZ/arch_2_configuracion.sh" "/mnt/tmp/arch_2_configuracion.sh"
chmod +x "/mnt/tmp/arch_2_configuracion.sh"

arch-chroot /mnt
