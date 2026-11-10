#!/bin/bash

tray_icon="$AUTO/memes_y_emotes/YuunaBox.png"

nt() {
	local N_ScriptName="${3:-$(basename "$0")}"
    local icono="$2"
    local mensaje="$1"
    local hint="$4"
    local tipo="$5"
	local args=()

    if [[ -n "$tipo" ]]; then
        args+=("-u" "$tipo")
    fi

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
	nt "$1" "${2:-$tray_icon}" "${3:-Script maestro}" "$4" "${5:-normal}"
}