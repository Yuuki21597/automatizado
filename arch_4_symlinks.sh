#!/usr/bin/env bash

AQUI="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"

if [[ -z "$AUTO" ]]; then
	AUTO="$AQUI"
	REPO="$(dirname "$AUTO")"
fi

# Inicio.
sudo ln -sf "$AUTO/servidor_ssh" "/etc/ssh/sshd_config"
ln -sf "$AUTO/recursos" "$HOME/.Xresources"
ln -sf "$AUTO/login_shell" "$HOME/.bash_profile"
ln -sf "$AUTO/interactive_shell" "$HOME/.bashrc"
sudo ln -sf "$AUTO/touchpad.conf" "/etc/X11/xorg.conf.d/40-touchpad.conf"

# Fuentes.
mkdir -p "$HOME/Documentos/Fuentes"
ln -sf "$HOME/Documentos/Fuentes" "$HOME/.local/share/fonts"
mkdir -p "$HOME/.config/fontconfig"
ln -sf "$AUTO/configuracion_de_fuentes" "$HOME/.config/fontconfig/fonts.conf"

# Sesión gráfica.
ln -sf "$AUTO/sesion_grafica" "$HOME/.xinitrc"
ln -sf "$AUTO/qtile.py" "$HOME/.config/qtile/config.py"

# Terminal y transparencia.
ln -sf "$AUTO/kitty.conf" "$HOME/.config/kitty/kitty.conf"
mkdir -p "$HOME/.config/picom"
ln -sf "$AUTO/picom.conf" "$HOME/.config/picom/picom.conf"

# Rofi.
mkdir -p "$HOME/.config/rofi"
ln -sf "$AUTO/rofi.rasi" "$HOME/.config/rofi/config.rasi"
# Aplicaciones.
ln -sf "$AUTO/accesos_directos" "$HOME/.local/share/applications"

# Cursores y temas de íconos.
ln -sf "$AUTO/gtk2.0" "$HOME/.config/gtkrc-2.0"
mkdir -p "$HOME/.config/gtk-3.0"
ln -sf "$AUTO/gtk3.ini" "$HOME/.config/gtk-3.0/settings.ini"
mkdir -p "$HOME/.config/gtk-4.0"
ln -sf "$AUTO/gtk4.ini" "$HOME/.config/gtk-4.0/settings.ini"
ln -sf "$REPO/temas" "$HOME/.themes"

# Thunar.
mkdir -p "$HOME/.config/Thunar"
ln -sf "$AUTO/renombrador_de_thunar" "$HOME/.config/Thunar/renamerrc"
ln -sf "$AUTO/comandos_de_thunar.xml" "$HOME/.config/Thunar/uca.xml"
mkdir -p "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/"
ln -sf "$AUTO/configuracion_de_thunar.xml" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml"

# Esto debe solucionar cualquier problema al abrir un archivo.
mkdir -p "$HOME/.config/xdg-desktop-portal"
ln -sf "$AUTO/portals.conf" "$HOME/.config/xdg-desktop-portal/portals.conf"
xdg-mime default thunar.desktop inode/directory

# Capturas, notificaciones y portapapeles.
mkdir -p "$HOME/.config/dunst"
ln -sf "$AUTO/dunst" "$HOME/.config/dunst/dunstrc"

# Entrada japonesa.
ln -sf "$AUTO/fcitx5-config" "$HOME/.config/fcitx5/config"
ln -sf "$AUTO/fcitx5-profile" "$HOME/.config/fcitx5/profile"

# Oh-my-posh-git.
mkdir -p "$HOME/.config/oh-my-posh"
ln -sf "$AUTO/terminal.omp.json" "$HOME/.config/oh-my-posh/$USER.omp.json"

# mpv.
mkdir -p "$HOME/.config/mpv"
ln -sf "$AUTO/mpv.conf" "$HOME/.config/mpv/mpv.conf"
ln -sf "$AUTO/mpv_input.conf" "$HOME/.config/mpv/input.conf"
mkdir -p "$HOME/.config/mpv/script-opts"
ln -sf "$AUTO/mpv_osc.conf" "$HOME/.config/mpv/script-opts/osc.conf"

# Reloj de imagen.
ln -sf "$REPO/reloj_de_anime/configuración_del_reloj.json" "$HOME/.config/img_clock_conf.json"