#!/usr/bin/env bash

# Cargado de datos sensibles.
AQUI="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
RAIZ="$(dirname "$AQUI")"
ENTORNO="$RAIZ/librerias/info.env"

if [[ -f "$ENTORNO" ]]; then
    source "$ENTORNO"
    echo "Variables de entorno cargadas desde: $ENTORNO"
else
    echo "Error: No se encontró el archivo .env en $ENTORNO" >&2
fi

source /tmp/variables.sh

# Primero pasamos la consola al español. Es lo más importante para poder leer cualquier cosa que pueda surgir después en el nuevo sistema.
nano /etc/locale.gen
locale-gen
echo "LANG=es_GT.UTF-8" > /etc/locale.conf
echo "KEYMAP=la-latin1" > /etc/vconsole.conf
export LANG=es_GT.UTF-8

# Luego ajustamos la hora para evitar cualquier problema que al internet pueda sucederle por tener hora asíncrona. No parece ser algo común, pero mejor prevenir.
ln -sfn /usr/share/zoneinfo/America/Guatemala /etc/localtime
timedatectl set-local-rtc 1 --adjust-system-clock
hwclock --systohc

# Finalmente configuramos la red local.
echo "Yuusha" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	Yuusha.localdomain	Yuusha
EOF

# La configuración de usuarios es lo primordial. Primero añadimos contraseña al usuario root y luego añadimos sudo para el control de seguridad habitual que se le atañe a GNU/Linux.
passwd
pacman -S sudo # 1 paquete (158 paquetes)
echo "EDITOR=nano" > /etc/environment
export EDITOR=nano
# Esto configura a nano como el editor del archivo de configuración de sudo, pero no funcionará hasta que se reinicie el equipo. Tras esto editamos el archivo de configuración de sudo para permitir a los usuarios wheel usarlo sin problemas. Para ello busca la linea:
# root ALL=(ALL:ALL) ALL
# y elimina la almohadilla del %wheel que habrá la línea por debajo más cercana.
EDITOR=nano visudo

useradd -m -g users -G wheel -s /bin/bash "$usuario"
echo "$usuario:$contra" | chpasswd

# Finalmente agregamos el gestor de arranque.
pacman -S grub os-prober # 2 paquetes (160 paquetes)

if [ "$MODO_ARRANQUE" == "UEFI" ]; then
  pacman -S efibootmgr # 2 paquetes (162 paquetes)
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch --removable
else
  grub-install --target=i386-pc "/dev/$DISCO_PRINCIPAL"
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Creo los directorios comunes a un usuario.
sudo pacman -S xdg-user-dirs
xdg-user-dirs-update

REPO="$HOME/Documentos/Repositorio"
cp "$RAIZ" "$REPO"

chmod +x "$REPO/instalacion_del_sistema/arch_3_aplicaciones.sh"

echo "Sal de nuevo sistema y reinicia la computadora."