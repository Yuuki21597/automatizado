#!/usr/bin/env bash

# El sistema tiene 163 paquetes hasta este momento.
# Este script se debe ejecutar desde un usuario normal.

instalador=("sudo" "pacman" "-S" "--needed")
gestor="${instalador[@]}"

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

# Configuración para usar ssh.
$gestor openssh
sudo ssh-keygen -A
sudo systemctl enable --now sshd.service
ssh-keygen -t ed25519 -C "$correo"

echo "Escribe el nombre del equipo. Esto ayudará a diferenciar entre algunos paquetes a instalar."
read EQUIPO

# Comienzo instalando los controladores gráficos.
if [ "$EQUIPO" == "Yuusha #01" ]; then
	paquetes=("nvidia-open")
elif [ "$EQUIPO" == "Yuusha #03" ]; then
	paquetes=("mesa" "intel-media-driver")
else
	paquetes=("")
fi

$gestor "${paquetes_1[@]}" vulkan-intel

# Controladores de audio.
$gestor pulseaudio pulseaudio-alsa pulseaudio-bluetooth blueman bluez-utils pavucontrol
systemctl --user enable --now pulseaudio.service
systemctl --user enable --now bluetooth.service

# Traté de usar wayland para la sesión gráfica, pero hay muchos problemas con él usando a Qtile como compositor. Así que la instalación se seguirá manteniendo en X11.
$gestor xorg-xinit xorg-server xorg-xrandr

$gestor qtile
# En una instalación fresca que usa a qtile como compositor para wayland, es necesario indicarle a qtile que tiene que gestionar el layout del teclado. Se añade from libqtile.backend.wayland import InputConfig y en wl_tools un diccionario con "input:keyboard": xb_layout=latam. Añado la indicación, pero no será necesario la mayor parte de las veces porque este script debería iniciarse desde mi carpeta de repositorio con un automatizado que debe copiar un archivo de configuración para qtile ya prehecho. Por otra parte, en Xorg se necesitan las herramientas de entrada, pero se añadirán luego, tras tener una interfaz mínima funcional.
sudo localectl --no-convert set-x11-keymap latam

# Para una sesión gráfica mínimamente funcional se necesita poder utilizar la consola.
$gestor kitty picom

# Rofi para el menú.
$gestor rofi

# Ya en condiciones, instalamos git para trabajar con repositorios propios y o externos. less se incluye para poder ver commits y cosas relacionadas con git en la terminal.
$gestor git less
git config --global user.name "$nombre_git"
git config --global user.email "$correo"

$gestor font-manager
update-desktop-database "$HOME/.local/share/applications/"
xdg-mime default com.github.FontManager.FontViewer.desktop application/x-font-ttf
xdg-mime default com.github.FontManager.FontViewer.desktop application/x-font-opentype
xdg-mime default com.github.FontManager.FontViewer.desktop font/ttf
xdg-mime default com.github.FontManager.FontViewer.desktop font/otf

# Se hace necesario para mayor comodidad usar Visual Studio Code. Requiere pasos previos para prepararlo de la mejor manera. Primero que todo, un gestor de archivos. Será Thunar porque puede manejar más de 40 000 archivos en un carpeta. Añado thunar-volman y gvfs para gestión de unidades externas y ntfs-3g para unidades externas ntfs. Esta última seguramente requiera intervención manual.
$gestor thunar thunar-volman gvfs ntfs-3g ntfsprogs exfatprogs xarchiver unzip unrar p7zip tumbler ffmpegthumbnailer libopenraw

# Capturas, notificaciones y portapapeles.
$gestor maim dunst copyq

# Entrada japonesa.
$gestor fcitx5 fcitx5-configtool fcitx5-mozc fcitx5-gtk

# Para poder autenticarse en VSCode y acceder a la sincronización de este, es necesario que VSCode pueda abrir una ventana de navegador para el login.
$gestor vivaldi
# Aquí dejaré por escrito las configuraciones de Vivaldi porque estas no se guardan en un archivito como yo quisiera...:
# General
# Página principal: Página de inicio.
# Iniciar con: Página principal.
# Cerrar y salir no tiene que tener nada activado.
# Idioma: Español.
# Prefencia de idioma de sitios web: es-419, en, ja.

# Apariencia
# Diseños predefinidos: Clásico.
# Apariencia de la ventana: activar 'Usar ventana nativa', 'Barras de desplazamiento simples'.
# Densidad de la interfaz de usuario: Compacta.
# Activar 'Estilo de menú compacto'.
# Zoom de la interfaz de usuario: 80%
# Activar 'Ocultar automáticamente la interfaz al usar pantalla completa'.

# Temas
# Instala este tema (Cosmic Vortex por ANANT777OP): https://themes.vivaldi.net/themes/0WV7AYjP7aX
# Programación de temas: Sin programación.

# Página de inicio
# Reabrir la página de accesos rápidos con: Primer grupo
# Widgets: Desactiva 'Activar widgets'.
# Accesos rápidos: Máximo de columnas: Ilimitado.
# Tamaño de los accesos rápidos: Mediano.

# Pestañas
# Página de pestaña nueva: Página principal
# Gestion de pestañas: Desactiva 'Confirmar al cerrar 3 o más pestañas'. Activar 'Ignorar doble clic'.
# Estilo de pestaña: Opciones de pestaña: Desactiva 'Mostrar consumo de memoria de las pestañas'.
# Función de las pestañas: Secuencia de cambio de pestaña: Activar 'Según su orden en la barra'.
# Pestañas ancladas: Activar 'Cerrar como las otras pestañas'.

# Búsqueda
# Buscador predeterminado: Google
# Buscador de imágenes: Google

# Rendimiento
# Ahorro de energía: Siempre ahorrar energía.
# Ahorro de memoria: Ahorro máximo.

# Descargas
# Ubicación de las descargas: "$HOME/Descargas" (Seleccionar manualmente).

# Páginas web
# Activar en modo de pantalla completa 'Ocultar cursor del ratón al activar pantalla completa'.
# Zoom por defecto en las páginas: 80%
# Modo lectura: Activar 'Permitir texto en dirección vertical'.

# Administrador de tareas.
$gestor resources

# Instalo libreoffice porque quiero escribir.
$gestor libreoffice-fresh libreoffice-fresh-es hunspell-es_gt hyphen-es papers
# Editor de imágenes para editar las capturas de pantalla o cualquier cosa relacionada.
$gestor krita

# Utilidades:
$gestor gnome-disk-utility discord obs-studio catfish redshift tailscale
sudo systemctl enable --now tailscaled.service
sudo tailscale configure systray --enable-startup=systemd
systemctl --user enable --now tailscale-systray

# Descargas de torrent y subtitulador.
$gestor qbittorrent aegisub

# WINE
$gestor wine-staging wine-mono winetricks zenity

# Emulador de GameCube.
$gestor dolphin-emu

# Hay que instalar un helper puesto que VSCode está en el AUR. Mi elección es yay.
$gestor base-devel
git clone https://aur.archlinux.org/yay.git
# Si llegase a fallar por algo relacionado con connection refused, es porque el DNS no puede resolver el nombre. Se arregla exportando de nuevo el enlace simbólico para systemd.
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
cd yay
makepkg -si

instalador=("yay" "-S" "--needed")
gestor="${instalador[@]}"

# Y finalmente instalo Visual Studio Code.
$gestor visual-studio-code-bin

$gestor iwgtk

# Rustdesk
$gestor rustdesk
systemctl enable --now rustdesk.service

# Visor de imágenes. Elijo nomacs por nomacs-git puesto que esta versión parece más cerca del git, por lo que se ve.
$gestor nomacs

# Cursores y tema de íconos.
$gestor bibata-cursor-git papirus-icon-theme

# Esto forma parte de la personalización de la consola, pero se instala desde el AUR, así que... hasta aquí.
$gestor -S oh-my-posh-git

# Pokéfinder, para RNG en Pokémon
$gestor pokefinder

# AIMP
$gestor aimp

# Qtile-extras, para personalización de Qtile.
$gestor qtile-extras

# Al instalar vbam-wx hay que cambiarla la flag -DENABLE_LINK porque la trae en False.
$gestor sfml vbam-wx melonds azahar-git ryujinx --editmenu

# Steam
sudo nano /etc/pacman.conf # Hay que activar el repositorio multilib
sudo pacman -Syu --needed steam

if [ "$EQUIPO" == "Yuusha #03" ]; then
	paquetes=("brightnessctl")
    $gestor "${paquetes_1[@]}"
fi

$gestor "${paquetes_1[@]}"

chmod +x "$RAIZ/arch_4_sysmlinks.sh"
$RAIZ/arch_4_sysmlinks.sh
