# pyright: reportInvalidTypeForm = false, reportAttributeAccessIssue = false

from libqtile.backend.x11.xcbq import Painter
from cairocffi import pixbuf, Context
from libqtile.log_utils import logger
from cairocffi.xcb import XCBSurface
from libqtile.backend.x11.core import Core as X11Core
from libqtile.layout.ratiotile import RatioTile as RTBase
from libqtile.backend.base.window import Window
from typing import Any
from os import listdir, path as os_ruta, getenv
from libqtile.layout.base import Layout as qtileLayout
from libqtile import layout, qtile as Core, bar, widget, resources, hook
from libqtile.utils import guess_terminal
from libqtile.config import Group, Drag, Click, Key, Screen, Match
from libqtile.lazy import lazy
from random import choice
from subprocess import run as subproceso, Popen as asíncrono


# ------------------------------------------------------------------------------
# Reimplementaciones.


# Painter para fondos de pantalla.
class NewPainter(Painter):
	def paint(self, screen, image_path, mode = None) -> None:
		try:
			with open(image_path, 'rb') as f:
				image, _ = pixbuf.decode_to_image_surface(f.read())
		except OSError:
			logger.exception('Could not load wallpaper: ')
			return
		
		self.fill(screen, screen.background if hasattr(screen, 'background') and screen.background is not None else COLORES['negro'])
		root_pixmap: int; surface: XCBSurface
		root_pixmap, surface = self._get_root_pixmap_and_surface(screen)

		context: Context = Context(surface)
		with context:
			context.translate(screen.x, screen.y)
			ancho_imagen: int = image.get_width()
			alto_imagen: int = image.get_height()
			offset_x: int | float = 0
			offset_y: int | float = 0
			escala: int | float = 1

			# fill
			if mode == 'recortar':
				context.rectangle(0, 0, screen.width, screen.height)
				context.clip()
				
				width_ratio: float = screen.width / ancho_imagen
				
				if width_ratio * alto_imagen >= screen.height:
					context.scale(width_ratio)
				else:
					height_ratio: float = screen.height / alto_imagen
					context.translate(-(ancho_imagen * height_ratio - screen.width) // 2, 0)
					context.scale(height_ratio)
			
			# stretch
			elif mode == 'estirar':
				context.scale(
					sx = screen.width / ancho_imagen,
					sy = screen.height / alto_imagen,
				)
			
			# center
			elif mode in ('centrar', 'escalar'):
				escala = min(screen.width / ancho_imagen, screen.height / alto_imagen)

				if escala > 1.333:
					escala = 1
					offset_x = (screen.width - ancho_imagen) / 2
					offset_y = (screen.height - alto_imagen) / 2
				else:
					n_width = int(ancho_imagen * escala)
					n_height = int(alto_imagen * escala)

					offset_x = (screen.width - n_width) / 2
					offset_y = (screen.height - n_height) / 2

					context.scale(escala)

			if mode in ('recortar', 'estirar', 'centrar'):
				context.set_source_surface(image)
			else:
				context.set_source_surface(image, x = int(offset_x / escala), y = int(offset_y / escala))

			context.paint()

		surface.finish()
		self._update_root_pixmap(root_pixmap)

def _implementacion_de_painter(self) -> NewPainter:
	if self._painter is None:
		self._painter = NewPainter(self._display_name)
	return self._painter

X11Core.painter = property(_implementacion_de_painter)


class RatioTile(RTBase):
	def add_client(self, w: Window) -> None:
		self.dirty = True
		self.clients.append(w)

# ------------------------------------------------------------------------------
# Definición de pantallas.

def obtener_monitores() -> list[Any]:
	monitores: list[Any] = []
	ruta_base: str = '/sys/class/drm'
	for carpeta in listdir(ruta_base):
		if carpeta.startswith('card') and '-' in carpeta:
			ruta: str = os_ruta.join(ruta_base, carpeta, 'status')
			if os_ruta.exists(ruta):
				with open(ruta, 'r') as archivo:
					if archivo.read().strip() == 'connected':
						monitores.append(carpeta)

	return monitores

MONITORES: list[Any] = obtener_monitores()

def hay_mas_de_una_pantalla(gestor = Core) -> bool:
	return len(MONITORES) > 1

RESOLUCIONES: list[tuple[int, int]] = [
	(1920, 1080),
	(1920, 1080)
]
POSICIONES: list[tuple[int, int]] = [
	(RESOLUCIONES[1][0] + 1, 0),
	(0, 0)
]
RES_STR: list[str] = [
	f'{x[0]}x{x[1]}' for x in RESOLUCIONES
]
POS_STR: list[str] = [
	f'{x[0]}x{x[1]}' for x in POSICIONES
]

def definir_resolución() -> str:
	global MONITORES

	if len(MONITORES) == 2:
		return f'xrandr --output HDMI-0 --primary --mode {RES_STR[0]} --pos {POS_STR[0]} --rotate normal --output HDMI-1-1 --mode {RES_STR[1]} --pos {POS_STR[1]} --rotate normal'
	else:
		return f'xrandr --output HDMI-0 --primary --mode {RES_STR[0]} --pos {POS_STR[0]} --rotate normal'

RESOLUCIÓN: str = definir_resolución()

# ------------------------------------------------------------------------------
# Variables.

TECLADO_NUMÉRICO: dict[str, str] = {
	'Numpad1': 'KP_End',
	'Numpad2': 'KP_Down',
	'Numpad3': 'KP_Next',
	'Numpad4': 'KP_Left',
	'Numpad5': 'KP_Begin',
	'Numpad6': 'KP_Right',
	'Numpad7': 'KP_Home',
	'Numpad8': 'KP_Up',
	'Numpad9': 'KP_Prior',
	'Numpad0': 'KP_Insert'
}

CLICK_IZQUIERDO: str = 'Button1'
CLICK_CENTRAL: str = 'Button2'
CLICK_DERECHO: str = 'Button3'

SCRIPT: str = getenv('SM', '')

TAMAÑO_DE_LOS_ÍCONOS: int = 18
ALTURA_DE_LA_BARRA: int = TAMAÑO_DE_LOS_ÍCONOS + (2 * 2)

ÁREAS: list[str] = [
	'Principal',
	'Secundario',
	'Juegos'
]

MARGEN_GENERAL: int = 3

CARPETAS_DE_FONDOS: list[Any] = []
FONDOS_DE_PANTALLA: list[str] = [
	os_ruta.join(os_ruta.dirname(resources.__file__), 'logo.png')
]
FONDOS_USADOS: set[Any] = set()

EXPLORADOR: str = 'thunar'
TERMINAL: str = guess_terminal() or 'kitty'

# ------------------------------------------------------------------------------
# Layouts y grupos.

COLORES: dict[str, str] = {
	'amarillo': '#f8d68f',
	'azul': '#5865f2',
	'blanco': '#eeeeee',
	'gris_claro': '#999999',
	'morado': '#004050',
	'naranja': '#ff7514',
	'negro': '#272727',
	'rojo': '#ff0000',
	'rojo indio': '#d75f5f',
	'transparente': '#00000000',
	'verde': '#366959'
}

AFINIDAD: dict[str, int] = {
	ÁREAS[1]: 1,
}

ESPECIFICACIONES: dict[str, int | str] = {
	'margin': MARGEN_GENERAL * 2,
	'border_focus': COLORES['verde'],
	'border_width': 3
}

LISTADO_DE_LAYOUTS: list[qtileLayout] = [
	layout.MonadTall(
		new_client_position = 'bottom',
		**ESPECIFICACIONES
	),
	layout.RatioTile(
		**ESPECIFICACIONES
	),
	layout.Matrix(
		**ESPECIFICACIONES
	),
	layout.Max(
		**ESPECIFICACIONES
	),
	layout.Max()
]

layouts: list[qtileLayout] = [
	*LISTADO_DE_LAYOUTS[0:-1]
]

LAYOUTS_POR_ÁREAS: dict[str, list[qtileLayout]] = {
	ÁREAS[2]: [
		LISTADO_DE_LAYOUTS[-1]
	]
}

groups: list[Group] = [
	Group(
		name = nombre,
		layouts = LAYOUTS_POR_ÁREAS.get(nombre, layouts),
		screen_affinity = AFINIDAD.get(nombre, 0)
	) for nombre in ÁREAS
]

# ------------------------------------------------------------------------------
# Atajos de teclado.

mouse: list[Drag | Click] = [
	Drag(
		['mod4'],
		CLICK_IZQUIERDO,
		lazy.window.set_position_floating(),
		start = lazy.window.get_position()
	),
	Click(
		['mod4'],
		CLICK_CENTRAL,
		lazy.window.toggle_floating()
	),
	Drag(
		['mod4'],
		CLICK_DERECHO,
		lazy.window.set_size_floating(),
		start = lazy.window.get_size()
	)
]

keys: list[Key] = [
	# --------------------------------------------------------------------------
	# Atajos de una sola tecla.

	Key(
		[],
		'F11',
		lazy.window.toggle_fullscreen(),
		desc = 'Activa y desactiva la pantalla completa de la ventana activa.'
	),

	# --------------------------------------------------------------------------
	# Atajos con Shift.

	# --------------------------------------------------------------------------
	# Atajos con Control.

	# --------------------------------------------------------------------------
	# Atajos con Alt.
	
	Key(
		['mod1'],
		'F4',
		lazy.window.kill(),
		desc = 'Cierra la ventana activa.'
	),

	# --------------------------------------------------------------------------
	# Atajos con Super.

	Key(
		['mod4'],
		'e',
		lazy.spawn(EXPLORADOR),
		desc = 'Abre el explorador de archivos.'
	),
	Key(
		['mod4'],
		'r',
		lazy.spawn(TERMINAL),
		desc = 'Abre el terminal.'
	),
	Key(
		['mod4'],
		'Return',
		lazy.spawn('rofi -show combi'),
		desc = 'Lanzador de aplicaciones.'
	),
	Key(
		['mod4', 'Control'],
		'r',
		lazy.reload_config(),
		desc = 'Recarga la configuración de Qtile.'
	),
	Key(
		['mod4', 'Control'],
		'q',
		lazy.shutdown(),
		desc = 'Quita Qtile.'
	)
]

for indice, área in enumerate(groups):
	keys.extend(
		[
			# 'mod4' + número del área de trabajo = cambia a esa área.
			Key(
				['mod4'],
				str(indice + 1),
				lazy.group[indice].toscreen(),
				desc = f'Cambia al área de trabajo "{área.name}".'
			),
			Key(
				['mod4'],
				TECLADO_NUMÉRICO[f'Numpad{indice + 1}'],
				lazy.group[indice].toscreen(),
				desc = f'Cambia al área de trabajo "{área.name}".'
			),
			# 'mod4' + Shift + número del área de trabajo = mueve la ventana activa a esa área.
			Key(
				['mod4', 'Shift'],
				str(indice + 1),
				lazy.window.togroup(área.name, switch_group = True),
				desc = f'Mueve la ventana activa al área de trabajo "{área.name}".'
			),
			Key(
				['mod4', 'Shift'],
				TECLADO_NUMÉRICO[f'Numpad{indice + 1}'],
				lazy.window.togroup(área.name, switch_group = True),
				desc = f'Mueve la ventana activa al área de trabajo "{área.name}".'
			)
		]
	)

# Esto es para Wayland: configuración por defecto.
for vt in range(1, 8):
	keys.append(
		Key(
			['Control', 'mod1'],
			f'f{vt}',
			lazy.core.change_vt(vt).when(func=lambda: Core.core.name == 'wayland'),
			desc=f'Cambia a la VT{vt}',
		)
	)

# ------------------------------------------------------------------------------
# Fondos de pantalla.

def crear_listado_de_fondos() -> None:
	global CARPETAS_DE_FONDOS
	global FONDOS_DE_PANTALLA

	extensiones: tuple[str, ...] = ('.png', '.jpg', '.jpeg', '.svg',  '.bmp')
	fondos: list[str] = []

	for carpeta in CARPETAS_DE_FONDOS:
		fondos += [os_ruta.join(carpeta, f) for f in listdir(carpeta) if f.lower().endswith(extensiones)]

	FONDOS_DE_PANTALLA += fondos

def seleccionar_fondo() -> str | None:
	global FONDOS_DE_PANTALLA
	global FONDOS_USADOS

	disponibles: list[str] = list(set(FONDOS_DE_PANTALLA) - FONDOS_USADOS)
	if disponibles:
		fondo: str = choice(disponibles)
		FONDOS_USADOS.add(fondo)
	
		return fondo

WIDGETS: list[Any] = [
	widget.CurrentLayout(),
	widget.GroupBox(),
	widget.WindowName(),
	widget.TextBox('personal config', name='default'),
	widget.TextBox('Presiona &lt;M-r&gt; para usar Rofi', foreground = '#d75f5f'),
	widget.Systray(),
	widget.Clock(format = '%Y-%m-%d %a %I:%M %p'),
	widget.QuickExit()
]

screens: list[Screen] = [
	Screen(
		top = bar.Bar(
			WIDGETS,
			background = COLORES['transparente'],
			size = ALTURA_DE_LA_BARRA
		),
		wallpaper = seleccionar_fondo(),
		wallpaper_mode = 'escalar'
	) for indice, pantalla in enumerate(MONITORES)
]

# ------------------------------------------------------------------------------
# Hooks.
@hook.subscribe.startup_once
def inicio_único() -> None:
	subproceso(RESOLUCIÓN.split())

	inicio_asíncrono: list[list[str]] = [
		[f'{SCRIPT}', 'consola', 'reiniciar-audio']
	]

	inicio_síncrono: list[list[str]] = []

	for comando in inicio_asíncrono:
		asíncrono(comando)

	for comando in inicio_síncrono:
		subproceso(comando)

# ------------------------------------------------------------------------------
# Configuración por defecto.

auto_fullscreen: bool = False
# Si las ventanas como Steam quiere minimizarse cuando pierden el foco, ¿debería permitirse?
auto_minimize: bool = True
bring_front_click: str = 'floating_only'
cursor_warp: bool = False
dgroups_app_rules: list = []
dgroups_key_binder = None
extension_defaults: dict[str, Any] = dict(
	font = 'sans',
	fontsize = 10,
	padding = 3,
)

layout.Floating.default_float_rules = [
	Match(wm_type="utility"),
	Match(wm_type="notification"),
	Match(wm_type="toolbar"),
	Match(wm_type="splash"),
	Match(wm_type="dialog"),
	Match(wm_class="file_progress"),
	Match(wm_class="confirm"),
	Match(wm_class="dialog"),
	Match(wm_class="download"),
	Match(wm_class="error"),
	Match(wm_class="notification"),
	Match(wm_class="splash"),
	Match(wm_class="toolbar"),
	Match(role="pop-up"),
	Match(func=lambda c: c.has_fixed_size()),
	Match(func=lambda c: c.has_fixed_ratio())
]

floating_layout: qtileLayout = layout.Floating(
	float_rules = [
		# Usa 'xprop' para ver el wm-class o el nombre de un cliente en X11.
		*layout.Floating.default_float_rules,
		Match(wm_class="confirmreset"),  # gitk
		Match(wm_class="makebranch"),  # gitk
		Match(wm_class="maketag"),  # gitk
		Match(wm_class="ssh-askpass"),  # ssh-askpass
		Match(title="branchdialog"),  # gitk
		Match(title="pinentry"),  # GPG key password entry
	],
	border_focus = COLORES['verde'],
	border_width = 3
)
floats_kept_above: bool = False
focus_on_window_activation: str = 'never'
focus_previous_on_window_remove: bool = False
follow_mouse_focus: str = 'click_or_drag_only'
reconfigure_screens: bool = True
idle_timers: list = []
idle_inhibitors: list = []
widget_defaults: dict[str, Any] = extension_defaults.copy()
# Los siguientes tres son para el backend con Wayland.
wl_input_rules: None = None
wl_xcursor_theme: None = None
wl_xcursor_size: int = 24
wmname: str = 'Qtile'