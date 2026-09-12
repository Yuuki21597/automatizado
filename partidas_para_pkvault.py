from os import getenv, path, remove, symlink

raíz: str = getenv('REPO', '')

ruta_actual: str = f'{raíz}/partidas_guardadas'
ruta_gestionada: str = f'{raíz}/banco_de_pokemon/partidas'

archivos_de_guardado: list = [
	'003 - Pokémon Azul.sav',
	'019 - Pokémon Rubí.sav',
	'021 - Pokémon Box Rubí y Zafiro.gci',
	'024 - Pokémon Colosseum.gci',
	'025 - Pokémon Rojo Fuego.sav',
	'027 - Pokémon Esmeralda.sav',
	'029 - Pokémon XD.gci',
	'036 - Pokémon Battle Revolution',
	'041 - Pokémon Platino.sav',
	'047 - Pokémon Oro HeartGold.sav',
	'051 - Pokémon Negro.sav',
	'060 - Pokémon Blanco 2.sav',
	'066 - Pokémon Y',
	'071 - Pokémon Rubí Omega',
	'078 - Pokémon Sol',
	'082 - Pokémon Ultraluna',
	'088 - Pokémon Escudo/0/main',
	'095 - Pokémon Leyendas Arceus/0/main',
	'097 - Pokémon Púrpura/0/main',
	'099 - Pokémon Leyendas Z-A/0/main',
]

for elemento in archivos_de_guardado:
	nombre: str

	if elemento.find('/0/') != -1:
		nombre = elemento[0:elemento.find('/0/')]
	else:
		nombre = elemento

	origen: str = f'{ruta_actual}/{elemento}'
	destino: str = f'{ruta_gestionada}/{nombre}'

	if path.exists(destino) or path.islink(destino):
		remove(destino)

	symlink(origen, destino)