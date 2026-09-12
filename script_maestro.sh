#!/usr/bin/env bash

# Este script contendrá todo aquello que quiero ejecutar en mi computadora porque tener cientos de scripts pequeños me parece una lata.

ENTORNO="$REPO/librerias/info.env"

if [[ -f "$ENTORNO" ]]; then
    source "$ENTORNO"
fi

nt() {
	local N_ScriptName="${3:-$(basename "$0")}"
    local icono="$2"
    local mensaje="$1"
    local hint="$4"
	local args=()

	if [[ -n "$icono" ]]; then
        args+=("-i" "$icono")
    fi

	if [[ -n "$hint" ]]; then
        args+=("-h" "$hint")
    fi

	args+=("$N_ScriptName" "$mensaje")

	notify-send "${args[@]}"
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

crear_swap() {
	ruta="/swapfile"
	size="${1:-2}G"

	# sudo dd if=/dev/zero of="$ruta" bs=1M count=2048 status=progress
	sudo fallocate -l "$size" "$ruta"
	sudo chmod 600 "$ruta"
	sudo mkswap "$ruta"
	sudo swapon "$ruta"
}

borrar_swap() {
	ruta="/swapfile"
	
	sudo swapoff "$ruta"
	sudo rm "$ruta"
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
# Seccion 2: Método de entrada y distribución del teclado.
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
# Sección 3: Consola.
	'consola')
		case "$2" in
			'reiniciar-audio')
				systemctl --user stop wireplumber.service
				# systemctl --user start wireplumber.service
				sleep 2
				pactl set-sink-volume @DEFAULT_SINK@ 67%
			;;

			'limpiar-actualización')
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
			
			'reemplazar-comodines')
				reemplazar_con_variables_globales "$3" "$4"
			;;

			'generar-configuración')
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
			'reiniciar-selector')
				dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP
				killall -9 xdg-desktop-portal xdg-desktop-portal-gtk 2>/dev/null
				/usr/lib/xdg-desktop-portal &
			;;
			'crear-swap')
				crear_swap $3
			;;
			'borrar-swap')
				borrar_swap
			;;
			'historial-de-tiradas-de-genshin')
				sudo pacman -S jq
				"$AUTO/historial_de_genshin.sh"
				sudo pacman -Rns jq
			;;
			# Filtro de visión nocturna
			'filtro')
				# Archivo para guardar el estado entre ejecuciones
				texto='Temperaturas usadas:'
				archivo_estado="/tmp/redshift_actual"
				claro=6500
				oscuro=2500
				valor=$3

				if [[ "$valor" =~ ^[0-9]+$ ]]; then
					modificador=${4:-Usuario}

					if [[ "$valor" -gt 25000 ]]; then
						valor=25000
					fi

					if [[ "$valor" -lt 1000 ]]; then
						valor=1000
					fi

					redshift -P -O "$valor"
					notificación "Filtro: ($valor K)" "/usr/share/icons/Papirus/128x128/apps/redshift.svg"

					cat << EOF > "$archivo_estado"
$valor
$modificador

$texto
$claro
$oscuro
EOF

					exit 0
				fi

				modificador=${3:-Usuario}

				# Se lee el estado guardado. Si no existe, valor por defecto.
				actual=$(awk 'NR==1' "$archivo_estado" || cat << EOF > "$archivo_estado"
6500
Sistema

$texto
$claro
$oscuro
EOF
				)

				if [[ "$actual" == "$claro" ]]; then
					redshift -P -O "$oscuro"
					notificación "Filtro: ($oscuro K)" "/usr/share/icons/Papirus/128x128/apps/redshift.svg" 
					
					cat << EOF > "$archivo_estado"
$oscuro
$modificador

$texto
$claro
$oscuro
EOF
				else
					redshift -P -O "$claro"
					notificación "Filtro: ($claro K)" "/usr/share/icons/Papirus/128x128/apps/redshift.svg"

					cat << EOF > "$archivo_estado"
$claro
$modificador

$texto
$claro
$oscuro
EOF
				fi
			;;
		esac
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
			'desmontaje_de_unidades')
				for unidad in $unidades_conectadas; do
					desmontaje "$unidad"
				done
			;;
		esac
	;;
# ------------------------------------------------------------------------------
# Sección 5: Seleccionador de memes.
	'meme')
		directorio="$AUTO/memes_y_emotes"

		if [[ ! -d "$directorio" ]]; then
			notificación "No se encontró la carpeta de memes."
			exit 1
		fi
		
		lista_de_memes=$(
			find "$directorio" -type f | while read -r file; do
				filename=$(basename "$file")
				echo -e "${filename}"
			done
		)

		seleccion=$(echo -e "$lista_de_memes" | rofi -dmenu -p "Memes" -i -theme "android_notification")

		echo "$seleccion"
		
		if [[ -n "$seleccion" ]]; then
			ruta_completa="$directorio/$seleccion"
			echo "$ruta_completa"
			if [[ -f "$ruta_completa" ]]; then
				extension=$(file --mime-type -b "$ruta_completa")
				if [[ "$extension" == "image/gif" ]]; then
					copyq write text/uri-list "file://$ruta_completa"
				else
					copyq write "$extension" - < "$ruta_completa"
				fi

				copyq select 0
				copyq paste
				notificación "$seleccion" "$ruta_completa" "Meme pegado"
			else
				notificación "No se pudo encontrar el archivo del meme seleccionado." "" "Error"
			fi
		fi
	;;
# ------------------------------------------------------------------------------
# Sección 6: Aplicaciones.
	'app')
		pkprefix="$HOME/.local/share/wineprefixes/PKHex"

		case $2 in
			'PKHex')
				WINEPREFIX="$pkprefix" renderer="vulkan" wine "$REPO/aplicaciones/pokehex/PKHeX.exe"
			;;
			'PKVault')
				dev="true"

				if [ "$dev" == "true" ]; then
					cd "$REPO/PKVault/PKVault.Desktop"
					WEBKIT_DISABLE_COMPOSITING_MODE=1 dotnet run /p:AllowMissingPrunePackageData=true
				else
					WEBKIT_DISABLE_COMPOSITING_MODE=1 "$REPO/aplicaciones/pkvault_app"
				fi
			;;
			'advren')
				WINEPREFIX="$pkprefix" renderer="vulkan" wine "$REPO/aplicaciones/advanced renamer/aren.exe"
			;;
			'mp3tag')
				WINEPREFIX="$pkprefix" renderer="vulkan" wine "$REPO/aplicaciones/mp3tag/Mp3tag.exe"
			;;
		esac
	;;
# ------------------------------------------------------------------------------
# Sección 7: Aplicaciones desde código.
	'codigo-fuente')
		case $2 in
			'qtile')
				if ! [ -d "$REPO/qtile" ]; then
					cd "$REPO"
					git clone https://github.com/qtile/qtile
				fi

				if ! [ -d "$REPO/entornos" ]; then
					python -m venv "$REPO/entornos/qtile-env"
				fi

				source "$REPO/entornos/qtile-env/bin/activate"
				cd "$REPO/qtile"
				pip install -e .
				deactivate
			;;
			'mpv')
				sudo pacman -S --needed lua luajit libxpresent
				
				if ! [ -d "$REPO/mpv" ]; then
					cd "$REPO"
					git clone https://github.com/mpv-player/mpv-build.git
				fi

				cd "$REPO/mpv-build"
				sudo pacman -S meson nasm vulkan-headers yt-dlp
				./rebuild -j6
				sudo ./install
				sudo pacman -Rns meson nasm vulkan-headers yt-dlp
			;;
		esac
	;;
# ------------------------------------------------------------------------------
# Fallback para errores.
	*)
		echo "Primer argumento desconocido."
	;;
esac
