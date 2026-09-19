#!/usr/bin/env bash

AQUI="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"

if [[ -z "$AUTO" ]]; then
	AUTO="$AQUI"
	REPO="$(dirname "$AUTO")"
fi

# Inicio.
sudo ln -sfn "$AUTO/servidor_ssh" "/etc/ssh/sshd_config"
ln -sfn "$AUTO/recursos" "$HOME/.Xresources"
ln -sfn "$AUTO/login_shell" "$HOME/.bash_profile"
ln -sfn "$AUTO/interactive_shell" "$HOME/.bashrc"
sudo ln -sfn "$AUTO/touchpad.conf" "/etc/X11/xorg.conf.d/40-touchpad.conf"

# Fuentes.
mkdir -p "$HOME/Documentos/Fuentes"
ln -sfn "$HOME/Documentos/Fuentes" "$HOME/.local/share/fonts"
mkdir -p "$HOME/.config/fontconfig"
ln -sfn "$AUTO/configuracion_de_fuentes" "$HOME/.config/fontconfig/fonts.conf"

# Sesión gráfica.
ln -sfn "$AUTO/sesion_grafica" "$HOME/.xinitrc"
ln -sfn "$AUTO/qtile.py" "$HOME/.config/qtile/config.py"

# Terminal y transparencia.
ln -sfn "$AUTO/kitty.conf" "$HOME/.config/kitty/kitty.conf"
mkdir -p "$HOME/.config/picom"
ln -sfn "$AUTO/picom.conf" "$HOME/.config/picom/picom.conf"

# Rofi.
mkdir -p "$HOME/.config/rofi"
ln -sfn "$AUTO/rofi.rasi" "$HOME/.config/rofi/config.rasi"
# Aplicaciones.
ln -sfn "$AUTO/accesos_directos" "$HOME/.local/share/applications"

# Cursores y temas de íconos.
ln -sfn "$AUTO/gtk2.0" "$HOME/.config/gtkrc-2.0"
mkdir -p "$HOME/.config/gtk-3.0"
ln -sfn "$AUTO/gtk3.ini" "$HOME/.config/gtk-3.0/settings.ini"
mkdir -p "$HOME/.config/gtk-4.0"
ln -sfn "$AUTO/gtk4.ini" "$HOME/.config/gtk-4.0/settings.ini"
ln -sfn "$REPO/temas" "$HOME/.themes"

# Thunar.
mkdir -p "$HOME/.config/Thunar"
ln -sfn "$AUTO/renombrador_de_thunar" "$HOME/.config/Thunar/renamerrc"
ln -sfn "$AUTO/comandos_de_thunar.xml" "$HOME/.config/Thunar/uca.xml"
mkdir -p "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/"
ln -sfn "$AUTO/configuracion_de_thunar.xml" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml"

# Esto debe solucionar cualquier problema al abrir un archivo.
mkdir -p "$HOME/.config/xdg-desktop-portal"
ln -sfn "$AUTO/portals.conf" "$HOME/.config/xdg-desktop-portal/portals.conf"
xdg-mime default thunar.desktop inode/directory

# Capturas, notificaciones y portapapeles.
mkdir -p "$HOME/.config/dunst"
ln -sfn "$AUTO/dunst" "$HOME/.config/dunst/dunstrc"

# Entrada japonesa.
ln -sfn "$AUTO/fcitx5-config" "$HOME/.config/fcitx5/config"
ln -sfn "$AUTO/fcitx5-profile" "$HOME/.config/fcitx5/profile"

# Oh-my-posh-git.
mkdir -p "$HOME/.config/oh-my-posh"
ln -sfn "$AUTO/terminal.omp.json" "$HOME/.config/oh-my-posh/$USER.omp.json"

# mpv.
mkdir -p "$HOME/.config/mpv"
ln -sfn "$AUTO/mpv.conf" "$HOME/.config/mpv/mpv.conf"
ln -sfn "$AUTO/mpv_input.conf" "$HOME/.config/mpv/input.conf"
mkdir -p "$HOME/.config/mpv/script-opts"
ln -sfn "$AUTO/mpv_osc.conf" "$HOME/.config/mpv/script-opts/osc.conf"

# Reloj de imagen.
ln -sfn "$REPO/reloj_de_anime/configuración_del_reloj.json" "$HOME/.config/img_clock_conf.json"