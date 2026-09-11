# pyright: reportInvalidTypeForm = false, reportAttributeAccessIssue = false

from libqtile.backend.x11.xcbq import Painter
from cairocffi import pixbuf, Context
from libqtile.log_utils import logger
from cairocffi.xcb import XCBSurface
from libqtile.backend.x11.core import Core as X11Core
from libqtile.backend.base.window import Window as WindowBase
from libqtile.layout.ratiotile import RatioTile as RTBase
from typing import Any
from os import listdir, path as os_ruta, getenv

import sys
lib = f'{getenv('REPO', '')}/librerias'
sys.path.append(lib)

from lib_recursos_nativos import notificación as nt

from libqtile.layout.base import Layout as qtileLayout
from libqtile import layout, qtile as Core, bar, widget, resources, hook
from libqtile.utils import guess_terminal
from libqtile.config import Group, Drag, Click, Key, Screen, Match
from libqtile.group import _Group as Grupo
from types import NoneType
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


class Window(WindowBase):
	def __init__(self) -> None:
		self._wm_class: str = ''
		super().__init__()
		self.recuperar_fullscreen: bool = False


class RatioTile(RTBase):
	def add_client(self, w: WindowBase) -> None:
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

AUTO: str = getenv('AUTO', '')
SCRIPT: str = getenv('SM', '')
ÍCONO: str = f'{AUTO}/imagenes/icono-qtile.png'

# ------------------------------------------------------------------------------
# Notificaciones.

def notificación(mensaje: str, icono: str = ÍCONO, título: str = 'Qtile', desktop_entry = '') -> None:
	nt(mensaje, icono, título, 'normal', desktop_entry)

# ------------------------------------------------------------------------------

TAMAÑO_DE_LOS_ÍCONOS: int = 18
ALTURA_DE_LA_BARRA: int = TAMAÑO_DE_LOS_ÍCONOS + (2 * 2)
MOSTRAR_BARRAS: list[bool] = [True for x in range(len(MONITORES))]

ÁREAS: list[str] = [
	'Principal',
	'Secundario',
	'Juegos'
]

MINIMIZADO: list[bool] = [False for área in ÁREAS]
PANTALLA_COMPLETA: list[Window | None] = [None for área in ÁREAS]
COMPORTAMIENTO_DE_ALT_TAB: str = 'Default'
ROTAR_ALT_TAB_EN_EL_GRUPO: bool = False

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

GROSOR_DEL_BORDE: int = 3
COLOR_DEL_BORDE: str = COLORES['verde']

LISTADO_DE_VENTANAS_ESPECIALES: list[dict[str, Any]] = []

VENTANAS_ESPECIALES: list[dict[str, Any]] = [
	{
		'titulo': ventana.get('titulo'),
		'match': ventana.get('match', {'title': ventana.get('titulo')}),
		'área': ventana.get('área', None),
		'tipo_de_ventana': ventana.get('tipo_de_ventana', 'Normal'),
		'saltar_alt_tab': ventana.get('saltar_alt_tab', False),
		'color_del_borde': ventana.get('color_del_borde', COLOR_DEL_BORDE),
		'grosor_del_borde': ventana.get('grosor_del_borde', GROSOR_DEL_BORDE),
		'tipo_de_cierre': ventana.get('tipo_de_cierre', 'Normal'),
		'tipo_de_pantalla_completa': ventana.get('tipo_de_pantalla_completa', 'Normal')
	} for ventana in LISTADO_DE_VENTANAS_ESPECIALES
]

ESPECIFICACIONES: dict[str, int | str] = {
	'margin': MARGEN_GENERAL * 2,
	'border_focus': COLOR_DEL_BORDE,
	'border_width': GROSOR_DEL_BORDE
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
# Listas de ventanas.

ventanas_de_cierre_forzado: list[str]; ventanas_de_cierre_especial: list[str]; ventanas_que_no_se_cierran: list[str]; ventanas_flotantes: list[str]; ventanas_estáticas: list[str]; ventanas_sin_foco: list[str];ventanas_con_pantalla_completa_especial: list[str]; ventanas_sin_pantalla_completa: list[str]
ventanas_de_cierre_forzado, ventanas_de_cierre_especial, ventanas_que_no_se_cierran, ventanas_flotantes, ventanas_estáticas, ventanas_sin_foco,ventanas_con_pantalla_completa_especial, ventanas_sin_pantalla_completa = [], [], [], [], [], [], [], []

for ventana in VENTANAS_ESPECIALES:
	titulo: str | None = ventana.get('titulo')

	if titulo is None:
		continue

	tipo_de_ventana: str | None = ventana.get('tipo_de_ventana')
	if tipo_de_ventana == 'Flotante':
		ventanas_flotantes.append(titulo)
	elif tipo_de_ventana == 'Estática':
		ventanas_estáticas.append(titulo)

	if ventana.get('saltar_alt_tab'):
		ventanas_sin_foco.append(titulo)

	tipo_de_cierre: str | None = ventana.get('tipo_de_cierre')
	if tipo_de_cierre == 'Forzado':
		ventanas_de_cierre_forzado.append(titulo)
	elif tipo_de_cierre == 'Especial':
		ventanas_de_cierre_especial.append(titulo)
	elif not tipo_de_cierre:
		ventanas_que_no_se_cierran.append(titulo)

	tipo_de_pantalla_completa: str | None = ventana.get('tipo_de_pantalla_completa')
	if tipo_de_pantalla_completa == 'Especial':
		ventanas_con_pantalla_completa_especial.append(titulo)
	elif not tipo_de_pantalla_completa:
		ventanas_sin_pantalla_completa.append(titulo)

# ------------------------------------------------------------------------------
# Control de ventanas.

def listado_de_ventanas(gestor: Core, un_solo_grupo: bool = False, grupo: Group | Grupo | None = None, excluir_flotantes: bool = False, excluir_minimizados: bool = False) -> list[Window]:
	listado: list[Window] = []
	ventanas: list[Window] = []

	grupos: list[Group | Grupo] = [gestor.current_screen.group if grupo is None else grupo] if un_solo_grupo else gestor.groups

	for grupo in grupos:
		listado.extend(grupo.windows)

	for app in listado:
		if (app.name in ventanas_sin_foco) or (app.minimized and excluir_minimizados) or (app.floating and not app.fullscreen and excluir_flotantes):
			continue
		else:
			ventanas.append(app)

	return ventanas

def control_de_pantalla_completa(ventana: Window, grupo: Group | Grupo) -> None:
	if not ventana or not ventana.fullscreen: return

	if isinstance(ventana.group, NoneType): raise TypeError('¡El grupo es None!')

	ventanas: list[Window] = listado_de_ventanas(gestor = ventana.group.qtile, un_solo_grupo = True, grupo = ventana.group, excluir_flotantes = True, excluir_minimizados = True)

	if (ventana.group.name == grupo.name) and len(ventanas) > 1:
		ventana.recuperar_fullscreen = True
		pantalla_completa(ventana.group.qtile, ventana)

def actualizar_barras() -> None:
	global MOSTRAR_BARRAS

	gestor: Core = Core
	
	pantalla: Screen = gestor.current_screen
	indice: int = pantalla.index

	MOSTRAR_BARRAS[indice] = not MOSTRAR_BARRAS[indice]

	for position in ['top', 'bottom', 'left', 'right']:
		barra: bar.Bar = getattr(pantalla, position)
		if barra:
			barra.show(MOSTRAR_BARRAS[indice])

def minimizar_grupo(gestor: Core, grupo: Group | None = None, excepciones: list[Window | None] | Window | None = None) -> None:
	global MINIMIZADO

	if gestor is None: return

	if isinstance(excepciones, (NoneType, WindowBase)):
		excepciones = [excepciones]

	grupo = grupo if grupo is not None else gestor.current_group
	indice: int = gestor.groups.index(grupo)
	ventanas: list[Window] = listado_de_ventanas(gestor = gestor, un_solo_grupo = True, grupo = grupo)

	minimizado: bool = MINIMIZADO[indice]

	for ventana in ventanas:
		if (not minimizado and ventana.minimized) or (minimizado and not ventana.minimized and ventana not in excepciones) or (minimizado is False and ventana in excepciones):
				continue
		
		ventana.toggle_minimize()

		if ventana in excepciones and ventana.minimized:
			ventana.toggle_minimize()

	MINIMIZADO[indice] = not minimizado

def pantalla_completa(gestor: Core, ventana: Window | None = None) -> None:
	global MOSTRAR_BARRAS, MINIMIZADO, PANTALLA_COMPLETA

	if not gestor:
		return
	
	ventana = gestor.current_window if ventana is None else ventana

	if not ventana or (ventana.name in ventanas_sin_pantalla_completa):
		if not MOSTRAR_BARRAS[gestor.current_screen.index]:
			actualizar_barras()
		return
	
	if (ventana.name in ventanas_con_pantalla_completa_especial) or ('nomacs' in ventana._wm_class):
		minimizar_grupo(gestor, excepciones = ventana)
		actualizar_barras()

		if MINIMIZADO[gestor.grupos.index(ventana.group)]: PANTALLA_COMPLETA[gestor.groups.index(ventana.group)] = ventana
		return
	
	if not MOSTRAR_BARRAS[gestor.current_screen.index]:
		actualizar_barras()
	
	if ventana.floating and not ventana.fullscreen:
		ventana.toggle_floating()

	ventana.toggle_fullscreen()

	if ventana.fullscreen: PANTALLA_COMPLETA[gestor.groups.index(ventana.group)] = ventana

def enfocar_grupo(gestor: Core, grupo: Group | Grupo) -> None:
	global COMPORTAMIENTO_DE_ALT_TAB

	pantalla_seleccionada: int | None = None

	if hay_mas_de_una_pantalla():
		if COMPORTAMIENTO_DE_ALT_TAB == 'Pantalla estática':

			for pantalla in gestor.screens:
				if pantalla.group.name == grupo.name:
					pantalla_seleccionada = pantalla.index
					break

		if pantalla_seleccionada is None or COMPORTAMIENTO_DE_ALT_TAB == 'Afinidad de pantalla':
			pantalla_seleccionada = grupo.screen_affinity

		if COMPORTAMIENTO_DE_ALT_TAB == 'Default':
			pantalla_seleccionada = gestor.current_screen.index

		gestor.focus_screen(pantalla_seleccionada, False)

	try:
		grupo.toscreen(pantalla_seleccionada)
	except AttributeError:
		gestor.groups_map[grupo.name].toscreen(pantalla_seleccionada)
	except Exception as error:
		notificación(f'Error: {error}')

def alt_tab(gestor: Core, tipo: str | None = None) -> None:
	global ROTAR_ALT_TAB_EN_EL_GRUPO, PANTALLA_COMPLETA
	ventanas: list[Window] = listado_de_ventanas(gestor = gestor, un_solo_grupo = ROTAR_ALT_TAB_EN_EL_GRUPO, excluir_minimizados = True)

	if not ventanas:
		notificación('No se encontraron ventanas.')
		return

	indice_ventana_actual: int = 0
	try:
		indice_ventana_actual = ventanas.index(gestor.current_window)
	except ValueError:
		indice_ventana_actual = 0 if tipo == 'Anterior' else -1
	except Exception as error:
		notificación(f'Error: {error}')

	indice: int
	if tipo == 'Siguiente':
		indice = (indice_ventana_actual + 1) % len(ventanas)
	elif tipo == 'Anterior':
		indice = (indice_ventana_actual - 1) % len(ventanas)
	else:
		indice = 0

	ventana: Window = ventanas[indice]
	if isinstance(ventana.group, NoneType): raise TypeError('¡El grupo es None!')
	grupo_de_ventana: Grupo = ventana.group

	control_de_pantalla_completa(gestor.current_window, grupo_de_ventana)

	if gestor.current_group != grupo_de_ventana:
		gestor.current_group.current_window = None
		enfocar_grupo(gestor, grupo_de_ventana)
		última_pantalla_completa: Window | None = PANTALLA_COMPLETA[gestor.groups.index(grupo_de_ventana)]
		if última_pantalla_completa is not None and (ventana != última_pantalla_completa):
			control_de_pantalla_completa(última_pantalla_completa, grupo_de_ventana)
			PANTALLA_COMPLETA[gestor.groups.index(grupo_de_ventana)] = None

	grupo_de_ventana.focus(ventanas[indice], False)

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
		'Tab',
		lazy.function(alt_tab, tipo = 'Siguiente'),
		desc = 'Mueve el foco a la siguiente ventana.'
	),
	Key(
		['mod1', 'Shift'],
		'Tab',
		lazy.function(alt_tab, tipo = 'Anterior'),
		desc = 'Mueve el foco a la ventana anterior.'
	),
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
		'v',
		lazy.spawn('copyq menu'),
		desc = 'Abre el historial del portapapeles.',
	),
	Key(
		['mod4'],
		'Space',
		lazy.spawn(f'{SCRIPT} metodo_de_entrada'),
		desc = 'Cambia el método de entrada.'
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
				lazy.group[área.name].toscreen(),
				desc = f'Cambia al área de trabajo "{área.name}".'
			),
			Key(
				['mod4'],
				TECLADO_NUMÉRICO[f'Numpad{indice + 1}'],
				lazy.group[área.name].toscreen(),
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
		[SCRIPT, 'consola', 'reiniciar-audio']
	]

	inicio_síncrono: list[list[str]] = [
		[SCRIPT, 'consola', 'reiniciar-selector']
	]

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