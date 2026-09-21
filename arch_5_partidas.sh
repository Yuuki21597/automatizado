#!/usr/bin/env bash

AQUI="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"

if [[ -z "$AUTO" ]]; then
	AUTO="$AQUI"
	REPO="$(dirname "$AUTO")"
fi

# Configuración de los emuladores.
mkdir -p "$HOME/.config/visualboyadvance-m"
ln -sfn "$AUTO/vbam.ini" "$HOME/.config/visualboyadvance-m/vbam.ini"

mkdir -p "$HOME/.config/melonDS"
ln -sfn "$AUTO/melonDS_conf" "$HOME/.config/melonDS/melonDS.toml"

mkdir -p "$HOME/.config/azahar-emu"
ln -sfn "$AUTO/azahar_config" "$HOME/.config/azahar-emu/qt-config.ini"

mkdir -p "$HOME/.config/Ryujinx"
ln -sfn "$AUTO/ryujinx.json" "$HOME/.config/Ryujinx/Config.json"

# Partidas.

mkdir -p "$HOME/.local/share/dolphin-emu/GC/EUR/Card A"

# Pokémon Box: Rubí y Zafiro
ln -sfn "$REPO/partidas_guardadas/021 - Pokémon Box Rubí y Zafiro.gci" "$HOME/.local/share/dolphin-emu/GC/EUR/Card A/01-GPXP-pokemon_rs_memory_box.gci"

# Pokémon Channel
ln -sfn "$REPO/partidas_guardadas/022 - Pokemon Channel.gci" "$HOME/.local/share/dolphin-emu/GC/EUR/Card A/01-GPAP-PCH4.BIN.gci"

# Pokémon Colosseum
ln -sfn "$REPO/partidas_guardadas/024 - Pokémon Colosseum.gci" "$HOME/.local/share/dolphin-emu/GC/EUR/Card A/01-GC6P-pokemon_colosseum.gci"

# Pokémon XD: Tempestad Oscura
ln -sfn "$REPO/partidas_guardadas/029 - Pokémon XD.gci" "$HOME/.local/share/dolphin-emu/GC/EUR/Card A/01-GXXP-PokemonXD.gci"

# Pokémon Battle Revolution
ln -sfn "$REPO/partidas_guardadas/036 - Pokémon Battle Revolution" "$HOME/.local/share/dolphin-emu/Wii/title/00010000/52504250/data"

rutas_azahar="$HOME/.local/share/azahar-emu/sdmc/Nintendo 3DS/00000000000000000000000000000000/00000000000000000000000000000000/title/00040000"
coletilla="data/00000001"

# 00055d00 --> Pokémon X

# Pokémon Y.
mkdir -p "$rutas_azahar/00055e00/$coletilla"
ln -sfn "$REPO/partidas_guardadas/066 - Pokémon Y" "$rutas_azahar/00055e00/$coletilla/main"

# Pokémon Rubí Omega.
mkdir -p "$rutas_azahar/0011c400/$coletilla"
ln -sfn "$REPO/partidas_guardadas/071 - Pokémon Rubí Omega" "$rutas_azahar/0011c400/$coletilla/main"

# 0011c500 --> Pokémon Zafiro Alfa

# Pokémon Sol.
mkdir -p "$rutas_azahar/00164800/$coletilla"
ln -sfn "$REPO/partidas_guardadas/078 - Pokémon Sol" "$rutas_azahar/00164800/$coletilla/main"

# Pokémon Ultraluna.
mkdir -p "$rutas_azahar/001b5100/$coletilla"
ln -sfn "$REPO/partidas_guardadas/082 - Pokémon Ultraluna" "$rutas_azahar/001b5100/$coletilla/main"

# ??? --> Pokémon Let's Go! Eevee # Es injugable mientras no descubra cómo lanzar Pokébolas.

rutas_ryujinx="$HOME/.config/Ryujinx/bis/user/save"
# Pokémon Escudo.
mkdir -p "$rutas_ryujinx/0000000000000001"
ln -sfn "$REPO/partidas_guardadas/088 - Pokémon Escudo" "$rutas_ryujinx/0000000000000001"

# ??? --> Pokémon Perla Reluciente (Supongo...)

# Leyendas Pokémon: Arceus.
mkdir -p "$rutas_ryujinx/0000000000000009"
ln -sfn "$REPO/partidas_guardadas/095 - Pokémon Leyendas Arceus" "$rutas_ryujinx/0000000000000009"

# Pokémon Púrpura.
mkdir -p "$rutas_ryujinx/0000000000000005"
ln -sfn "$REPO/partidas_guardadas/097 - Pokémon Púrpura" "$rutas_ryujinx/0000000000000005"

# ??? --> Pokémon Leyendas: Z-A