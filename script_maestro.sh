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
			
			generar-configuracion)
				envsubst < "$3" > "$4"
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
# Fallback para errores.
	*)
		echo "Primer argumento desconocido."
	;;
esac
