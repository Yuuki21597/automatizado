#!/bin/bash

source "$AUTO/utilitarios.sh"

valor_bajo=20
valor_muy_bajo=10

while true; do
    nivel=$(acpi -b | grep -P -o '[0-9]+(?=%)')
    estado=$(acpi -b | grep -c "Discharging")

    if [ "$estado" -eq 1 ] && [ "$nivel" -le "$valor_bajo" ] && [ "$nivel" -gt "$valor_muy_bajo" ]; then
        notificación "Nivel actual: ${nivel}%" "" "¡Batería baja!"
    elif [ "$estado" -eq 1 ] && [ "$nivel" -le "$valor_muy_bajo" ]; then
        notificación "Conecta el cargador: ${nivel}%" "" "¡Batería muy baja!" "" "critical" 
    fi
    sleep 120
done
