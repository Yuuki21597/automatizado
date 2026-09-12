#!/usr/bin/env bash

# Este script contendrá todo aquello que quiero ejecutar en mi computadora porque tener cientos de scripts pequeños me parece una lata.

ENTORNO="$REPO/librerias/info.env"

if [[ -f "$ENTORNO" ]]; then
    source "$ENTORNO"
fi

nt() {
	N_ScriptName=${3:-(basename "$0")}
	args=("-i" "$2" "$N_ScriptName" "$1")
	if [[ -z $4 ]]; then
		notify-send ${args[@]}
	else
		notify-send -h "$4" ${args[@]}
	fi
}

notificación() {
	nt "$1" "${2:-$tray_icon}" "${3:-Script maestro}" "$4"
}

reemplazar_con_variables_globales() {
	envsubst < "$1" > "$2"
}

listado_de_unidades() {
	ignorar_etiquetas=(
		"UEFI"
		"VTOYEFI"
	)

	ignorar_uuid=(
		"EE3C-A774"                                 # UEFI
		"6b08f856-edab-4e47-916a-0f5ffff24c44"      # Yuusha #01
		"F331-EB4E"									# VTOYEFI
	)

	ignorar_unidades=()

	no_desmontar=(
		"/boot/efi"
		"/"
	)

	unidades_conectadas=$(lsblk -n -P -o NAME,TYPE,LABEL | sort -t'"' -k6 | awk -F '"' '$4 == "part" {print $2}')
}

montar() {
	local etiqueta=$1

	local unidad=$(lsblk -n -P -o LABEL,NAME | grep "LABEL=\"$etiqueta\"" | awk -F '"' '{print $4}')

	if [[ -z "$unidad" ]]; then
		notificación "No se encontró $etiqueta." "/usr/share/icons/Papirus/128x128/apps/xfce4-fsguard-plugin-warning.svg"
		exit 1
	fi

	montaje "$unidad"
}

desmontaje() {
	local unidad=$1

	local etiqueta=$(lsblk -rno NAME,LABEL | awk -v u="$unidad" '$1==u {print $2}' | sed 's/\\x20/ /g')

	if [[ -z "$etiqueta" ]]; then
        notificación "No se encontró $unidad." "/usr/share/icons/Papirus/128x128/apps/xfce4-fsguard-plugin-warning.svg"
        return
    fi

	desmontar "$etiqueta"
}

desmontar() {
	local etiqueta=$1
	local etiqueta_escapada="${etiqueta/ /\\\\x20}"
	local punto_de_montaje=$(lsblk -rno LABEL,MOUNTPOINT | awk -v e="$etiqueta_escapada" '$1==e {print $2}')
	local punto_de_montaje="${punto_de_montaje/\\x20/ }"

	if [[ -z "$punto_de_montaje" ]]; then
        notificación "$etiqueta no está montado." "/usr/share/icons/Papirus/128x128/apps/xfce4-fsguard-plugin-warning.svg"
        return
    fi

	if echo "${no_desmontar[@]}" | grep -q "$punto_de_montaje"; then
		notificación "$etiqueta no se desmontará." "/usr/share/icons/Papirus/128x128/apps/xfce4-fsguard-plugin-warning.svg"
		return
	fi

	if mountpoint -q "$punto_de_montaje"; then
		echo "$contra" | sudo -S umount "$punto_de_montaje"
		echo "$contra" | sudo -S rm -d "$punto_de_montaje"
		notificación "Se ha desmontado $etiqueta." "/usr/share/icons/Papirus/128x128/devices/drive-removable-media.svg"
	fi
}

montaje() {
	local unidad=$1

	local uuid=$(lsblk -ln -o UUID,NAME | grep "$unidad" | awk '{print $1}')
	local etiqueta=$(lsblk -n -P -o LABEL,NAME | grep "$unidad" | awk -F '"' '{print $2}')
	local tipo=$(lsblk -n -P -o FSTYPE,NAME | grep "$unidad" | awk -F '"' '{print $2}')
	local punto_de_montaje="/run/media/$USER/$etiqueta"
	local opciones="rw"

	if (echo "${ignorar_etiquetas[@]}" | grep -q "$etiqueta") || (echo "${ignorar_uuid[@]}" | grep -q "$uuid") || (echo "${ignorar_unidades[@]}" | grep -q "$unidad"); then
		notificación "$etiqueta no se montará." "/usr/share/icons/Papirus/128x128/apps/rtt-rlinux.svg"
		return
	fi

	if ( mount | grep -q "/dev/$unidad" ); then
		notificación "$etiqueta ya está montado." "/usr/share/icons/Papirus/128x128/apps/disk-usage-analyzer.svg"
		return
	fi

	if [[ $tipo == 'ntfs' ]]; then
		notificación "$etiqueta es una unidad NTFS. Ejecutando reparación para evitar errores al montarlo." "/usr/share/icons/Papirus/128x128/apps/disk-utility.svg"
		echo "$contra" | sudo -S ntfsfix -d -b "/dev/$unidad"
		opciones+=",uid=1000,gid=1000"
		tipo="ntfs-3g"
	elif [[ $tipo == 'exfat' ]]; then
		notificación "$etiqueta es una unidad exFAT. Verificando integridad..." "/usr/share/icons/Papirus/128x128/apps/disk-utility.svg"
		echo "$contra" | sudo -S fsck.exfat -p "/dev/$unidad"
		opciones+=",uid=1000,gid=1000,fmask=0022,dmask=0022"
	fi

	echo "$contra" | sudo -S mkdir -p "$punto_de_montaje"
	echo "$contra" | sudo -S mount -t "$tipo" -o "$opciones" "/dev/$unidad" "$punto_de_montaje"

	if [[ $tipo == 'ext4' || $tipo == 'ext3' || $tipo == 'ext2' ]]; then
        echo "$contra" | sudo -S chown -R "$USER:" "$punto_de_montaje"
    fi

	notificación "Se ha montado $etiqueta." "/usr/share/icons/Papirus/128x128/devices/drive-removable-media.svg"
}

case $1 in
# ------------------------------------------------------------------------------
# Sección 1: Arranque del sistema.
	'inicio')
		case "$2" in
			'qtile'|'qtile-dev')
				startx "$HOME/.xinitrc" "$2" "$@"
			;;

			*)
				mensaje="Entorno de escritorio desconocido: $2"
				echo "$mensaje"
				notificación "$mensaje" "/usr/share/icons/Papirus/128x128/apps/distributor-logo-archlinux.svg"
				exit 1
			;;
		esac
	;;
# ------------------------------------------------------------------------------
# Sección 2: Consola.
	'consola')
		case "$2" in
			reiniciar-audio)
				systemctl --user stop wireplumber.service
				# systemctl --user start wireplumber.service
				sleep 2
				pactl set-sink-volume @DEFAULT_SINK@ 67%
			;;

			limpiar-actualización)
				gestor="yay"

				if ! (command -v "$gestor" &>/dev/null); then
					gestor="pacman"
				fi

				paquetes_listados=("go" "yay-debug" "oh-my-posh-git-debug" "cubeb-debug" "zahar-git-debug" "nomacs-debug" "catch2" "aimp-debug" "iwgtk-debug" "jq" "oniguruma" "adwaita-fonts" "gnu-free-fonts" "ttf-jetbrains-mono")

				huerfanos=()
				mapfile -t huerfanos < <($gestor -Qdttq 2>/dev/null)
				paquetes_listados+=("${huerfanos[@]}")

				paquetes_a_borrar=()
				for paquete in "${paquetes_listados[@]}"; do
					if $gestor -Qq "$paquete" &>/dev/null; then
						paquetes_a_borrar+=("$paquete")
					fi
				done

				if [ ${#paquetes_a_borrar[@]} -gt 0 ]; then
					if [[ "$gestor" == "pacman" ]]; then
						echo "$contra" | sudo -S pacman -Rddns --noconfirm "${paquetes_a_borrar[@]}"
					else
						$gestor -Rddns --noconfirm "${paquetes_a_borrar[@]}"
					fi
				else
					echo "No hay paquetes por eliminar instalados."
				fi
			;;
			
			reemplazar-comodines)
				reemplazar_con_variables_globales "$3" "$4"
			;;

			generar-configuración)
				# Rofi.
				reemplazar_con_variables_globales "$AUTO/plantilla_de_rofi" "$AUTO/rofi.rasi"

				# Oh-my-posh.
				archivo_tmp="$AUTO/temporal"
				archivo_final="$AUTO/terminal.omp.json"
				sed "s/WindowsUserName/$windows_user_name/g" "$AUTO/plantilla_de_omp.json" > "$archivo_tmp"
				sed -i "s/PreferredUserName/$preferred_user_name/g" "$archivo_tmp"
				reemplazar_con_variables_globales "$archivo_tmp" "$archivo_final"

				ruta="\/run\/media\/$USER\/Yuusha #12"
				# vbam
				archivo_final="$AUTO/vbam.ini"
				sed "s/carpeta/$ruta/g" "$AUTO/plantilla_de_vbam" > "$archivo_tmp"
				reemplazar_con_variables_globales "$archivo_tmp" "$archivo_final"

				# MelonDS
				archivo_final="$AUTO/melonDS_conf"
				sed "s/carpeta/$ruta/g" "$AUTO/plantilla_de_melonds" > "$archivo_tmp"
				reemplazar_con_variables_globales "$archivo_tmp" "$archivo_final"

				# Azahar
				archivo_final="$AUTO/azahar_config"
				sed "s/carpeta/$ruta/g" "$AUTO/plantilla_de_azahar" > "$archivo_tmp"
				reemplazar_con_variables_globales "$archivo_tmp" "$archivo_final"

				# Ryujinx
				archivo_final="$AUTO/ryujinx.json"
				sed "s/carpeta/$ruta/g" "$AUTO/plantilla_de_ryujinx" > "$archivo_tmp"
				reemplazar_con_variables_globales "$archivo_tmp" "$archivo_final"

				rm -f "$archivo_tmp"
			;;

			reiniciar-selector)
				dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP
				killall -9 xdg-desktop-portal xdg-desktop-portal-gtk 2>/dev/null
				/usr/lib/xdg-desktop-portal &
			;;
		esac
	;;
# ------------------------------------------------------------------------------
# Seccion 3: Método de entrada y distribución del teclado.
	'metodo_de_entrada')
		motores=(
			"keyboard-latam-deadtilde"	# Español latino
			"mozc"						# Japonés
		)

		# Motor actual
		actual=$(fcitx5-remote -n)

		# Encuentra el índice actual
		indice=-1
		for i in "${!motores[@]}"; do
			if [[ "${motores[$i]}" == "$actual" ]]; then
				indice=$i
				break
			fi
		done

		# Calcula el siguiente índice (con ciclo)
		indice_siguiente=$(( (indice + 1) % ${#motores[@]} ))

		# Establece el siguiente engine
		motor_siguiente="${motores[$indice_siguiente]}"

		fcitx5-remote -s "$motor_siguiente"
	;;
# ------------------------------------------------------------------------------
# Sección 4: Control de unidades extraíbles.
	'unidades')
		listado_de_unidades

		case $2 in
			'montar')
				if [[ -n "$3" ]]; then
					montar "$3"
				fi
			;;
			'desmontar')
				if [[ -n "$3" ]]; then
					desmontar "$3"
				fi
			;;
			'montaje_de_unidades')
				for unidad in $unidades_conectadas; do
					montaje "$unidad"
				done
			;;
			desmontaje_de_unidades)
				for unidad in $unidades_conectadas; do
					desmontaje "$unidad"
				done
			;;
		esac
	;;
# ------------------------------------------------------------------------------
# Fallback para errores.
	*)
		echo "Primer argumento desconocido."
	;;
esac
