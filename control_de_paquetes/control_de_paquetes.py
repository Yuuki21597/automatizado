import subprocess
from collections import Counter
from os import getenv

ubicación: str = getenv('AUTO', '')
ruta: str = f'{ubicación}/control_de_paquetes/listado_general_de_paquetes.txt'

NOMBRE_EQUIPO: str = getenv('NOMBRE_EQUIPO', 'Yuusha #01')
ruta_específicos: str
if NOMBRE_EQUIPO == 'Yuusha #03':
	ruta_específicos = f'{ubicación}/control_de_paquetes/paquetes_de_yuusha_03.txt'
else:
	ruta_específicos = f'{ubicación}/control_de_paquetes/paquetes_de_yuusha_01.txt'

with open(ruta, 'r', encoding='utf-8') as archivo:
    paquetes_listados_1: list[str] = [line.strip() for line in archivo if line.strip()]

with open(ruta_específicos, 'r', encoding='utf-8') as archivo:
    paquetes_listados_2: list[str] = [line.strip() for line in archivo if line.strip()]

paquetes_listados: list[str] = paquetes_listados_1 + paquetes_listados_2

resultado: subprocess.CompletedProcess[str] = subprocess.run(['yay', '-Qq'], capture_output=True, text=True)

paquetes_instalados: list[str] = [line.strip() for line in resultado.stdout.splitlines() if line.strip()]

conteo_listados: Counter[str] = Counter(paquetes_listados)
duplicados_en_lista: list[str] = [item for item, count in conteo_listados.items() if count > 1]

set_paquetes_listados: set[str] = set(paquetes_listados)
set_paquetes_instalados: set[str] = set(paquetes_instalados)

paquetes_sobrantes: list[str] = list(set_paquetes_instalados - set_paquetes_listados)
paquetes_faltantes: list[str] = list(set_paquetes_listados - set_paquetes_instalados)

if duplicados_en_lista:
	print(f'Paquetes listados más de una vez: {duplicados_en_lista}')
print(f'Paquetes instalados: {len(set_paquetes_instalados)}')
print(f'Paquetes listados: {len(set_paquetes_listados)}')
print(f'Paquetes sobrantes (no deseados): {len(paquetes_sobrantes)}')
print(f'Paquetes faltantes (no instalados aún): {len(paquetes_faltantes)}')

ruta_salida_1: str = f'{ubicación}/control_de_paquetes/paquetes_sobrantes.txt'
with open(ruta_salida_1, 'w', encoding = 'utf-8') as archivo_salida_1:
	archivo_salida_1.write('\n'.join(paquetes_sobrantes))

ruta_salida_2: str = f'{ubicación}/control_de_paquetes/paquetes_faltantes.txt'
with open(ruta_salida_2, 'w', encoding = 'utf-8') as archivo_salida_2:
	archivo_salida_2.write('\n'.join(paquetes_faltantes))

print(f'Proceso finalizado.')
