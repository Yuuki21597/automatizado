from os import getenv
from pathlib import Path

AUTO: str = getenv('AUTO', '')
SM: str = getenv('SM', '')

datos: list[list[str]] = [
	['advance_renamer', 'Advance Renamer', f'{SM} app advren', f'{AUTO}/imagenes/icono-advance-renamer.png'],
	['genshin_impact', 'Genshin Impact', 'steam steam://rungameid/10029789293884473344', f'{AUTO}/imagenes/icono-genshin-impact.png'],
	['memes', 'Memes', f'{SM} meme', f'{AUTO}/memes_y_emotes/YuunaWtf.png'],
	['mp3tag', 'mp3tag', f'{SM} app mp3tag', f'{AUTO}/imagenes/icono-mp3tag.png'],
	['pkvault', 'PKVault', f'{SM} app PKVault', f'{AUTO}/imagenes/icono-pkvault.svg'],
	['pkhex', 'PKHex', f'{SM} app PKHex', f'{AUTO}/imagenes/icono-pkhex.png'],
]

entradas_de_menu: list = [
	{
		'archivo': x[0],
		'nombre': x[1],
		'comando': x[2],
		'icono': x[3]
	} for x in datos
]

directorio = Path(f'{AUTO}/accesos_directos')
directorio.mkdir(parents = True, exist_ok = True)

for entrada in entradas_de_menu:
	contenido = f"""[Desktop Entry]
Name={entrada['nombre']}
Exec={entrada['comando']}
Icon={entrada['icono']}
Type=Application
Comment=
Path=
Terminal=False
StartupNotify=False
"""
	ruta_de_archivo = f'accesos_directos/{entrada['archivo']}.desktop'
	with open(f'{AUTO}/{ruta_de_archivo}', 'w', encoding = 'utf-8') as archivo:
		archivo.write(contenido)

	with open(f'{AUTO}/.gitignore', 'r+', encoding = 'utf-8') as archivo:
		lineas = archivo.readlines()
		if ruta_de_archivo not in lineas and ruta_de_archivo + '\n' not in lineas:
			archivo.write(f'\n{ruta_de_archivo}')