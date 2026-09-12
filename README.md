<h1 align="center"> Automatizado </h1>

Repositorio que automatiza diversas tareas que he repetido en mi estancia en Arch Linux. Los he abstraído tanto como he podido; si deseas usarlo, se recomienda fuertemente leerlos y editarlos según sea necesario.

Estas son algunas de las tareas automatizadas:
 - **Instalación del Arch Linux**: Los archivos «arch_no» contienen scripts para automatizar la instalación del sistema. Aunque lo parezca, no ejecutarán automáticamente en sucesión. **Depende de un archivo bajo el nombre «info.env»**. Este archivo contiene la información sensible y los scripts lo buscarán la carpeta «librerías» de la siguiente forma:
<br>&emsp; Carpeta raíz
<br>&emsp;&emsp;|- automatizado (Esta carpeta)
<br>&emsp;&emsp;|- librerías
<br>&emsp;&emsp;| &emsp;**|- info.env**
<br>&emsp;&emsp;| &emsp;|- otros_archivos
<br>&emsp;&emsp;|- otras_carpetas
 - **Lanzar X11**: Siento cierta magia usar la terminal para iniciar una sesión gráfica. Usé XFCE mientras configuraba Qtile para evitar quedarme sin acceso a una interfaz gráfica cuando rompía Qtile. Por eso esta configuración existe.
 <br>Para añadirlo cualquier un entorno de escritorio o un gestor de ventanas, hay que editar el archivo «[sesion_grafica](sesion_grafica)» y el [script maestro](script_maestro.sh).
 <br>Usarlo es tan simple como escribir «**iniciar**» en la tty.
 - **Tareas de consola**: YouTube carga eternamente, el audio baja solito, no abre la ventana para elegir donde guardar el archivo que quiero descargar... Problemas recurrentes en mi equipo. Estas tareas resuelven esos problemas. Están listadas en la sección dos del [script maestro](script_maestro.sh).
 - **Método de entrada**: ¿Qué puedo decir? Me acostumbré em Windows a presionar Super + Espacio para cambiar de idioma al escribir. **レッツエンジョイ！　香川ライフ！**
 <br>Para usarlo hay que llamar al [script maestro](script_maestro.sh) desde donde se asigne el atajo. Los idiomas se añaden [aquí](script_maestro.sh#248).
 - [**Qtile**](https://github.com/qtile/qtile): Mi gestor de ventanas favorito. Es de lo que más irá este repositorio, ya que la gestión de las ventanas hacen más fácil y cómodo mi uso de Arch Linux.