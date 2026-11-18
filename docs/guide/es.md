# DRX to LUT — Guía de uso
v{{VERSION}} · DaVinci Resolve Studio 21.2 · macOS 13+ (Apple silicon)

## 1. Qué hace
DRX to LUT convierte una corrección hecha en DaVinci Resolve en un LUT .cube 65³. Exportas la corrección de Resolve como archivo DRX, la sueltas en la aplicación, ves qué nodos pueden ir en un LUT, confirmas la entrada y la salida y pulsas «Crear LUT 65». Todo se ejecuta en tu Mac; no se sube nada.

## 2. Antes de empezar
- DaVinci Resolve Studio debe estar abierto, con scripting externo activado: Preferences > System > General > External scripting using > Local. La aplicación se verificó con Resolve Studio 21.2; otras versiones y la edición gratuita no se verificaron.
- Los efectos OFX usados en el DRX (por ejemplo GDC STYLE Client, instalado por separado) deben estar instalados en este Mac. Si falta alguno, la aplicación lo dice y no crea nada, porque el LUT estaría incompleto.
- Guarda primero tu propio proyecto de Resolve. La aplicación trabaja en un proyecto aparte llamado «DRX to LUT - work project». Si Resolve está en otro proyecto, la aplicación pregunta antes de cambiar y después te ofrece volver al tuyo. La aplicación nunca guarda tu proyecto.

## 3. Instalación
Abre DRXtoLUT-{{VERSION}}.pkg, sigue el instalador (pide la contraseña de tu Mac) y abre DRX to LUT desde Aplicaciones. La primera vez, macOS puede pedir confirmación para abrir una aplicación descargada de internet; la aplicación está firmada con un certificado Developer ID y notarizada por Apple.

## 4. Exporta un DRX desde Resolve
En la página Color, corrige un clip. Captura un still (clic derecho en el visor > Grab Still). En la galería, haz clic derecho en el still, elige Export, el formato DRX y un nombre.

## 5. Crea el LUT
Suelta el DRX en la ventana o pulsa «Elegir DRX…».
![idle]
La aplicación abre la corrección en Resolve y lista los nodos. Marca los nodos que deben ir en el LUT. Los nodos que no pueden estar en un LUT quedan excluidos y bloqueados.
![review]
Lee el cuadro Entrada y salida y marca la confirmación. Elige el nombre y la carpeta de destino y pulsa «Crear LUT 65». Una barra de progreso muestra los pasos; Cancelar se detiene con seguridad y no deja ningún archivo incompleto. Si ya existe un archivo con el mismo nombre, la aplicación pregunta antes de reemplazarlo.
![done]
En la carpeta obtienes: el .cube, una copia del DRX, un archivo de notas (.README.txt) y un archivo legible por máquina (.lutinfo.json).

## 6. Aplica el LUT correctamente en Resolve
1. En Resolve abre Project Settings > Color Management > Lookup Tables y pulsa «Open LUT Folder». Copia ahí el .cube y pulsa «Update Lists».
2. En un nodo de tu clip, clic derecho > 3D LUT y elige el archivo. Pon la interpolación 3D LUT en Tetrahedral.
3. El clip debe estar en el espacio de color de entrada que confirmaste en la aplicación. No añadas por segunda vez las transformaciones de entrada o salida: el LUT ya contiene los nodos marcados.

## 7. Lo que un LUT no puede contener
Un LUT cambia el color píxel a píxel. Desenfoque, grano, halación, reducción de ruido, máscaras, seguimiento y todo lo que dependa de píxeles vecinos o de otros fotogramas no puede estar en un LUT. La aplicación usa cuatro etiquetas:
- Entra en el LUT: operaciones de color píxel a píxel que la aplicación reconoce.
- No puede estar en un LUT: efectos espaciales o temporales. Excluidos automáticamente y anotados en las notas.
- Efecto desconocido: un efecto OFX que la aplicación no puede clasificar. Excluido por defecto; decides tú.
- Operación de Resolve no identificada: las herramientas nativas de Resolve no pueden identificarse del todo. Desenfoque, reducción de ruido, máscaras o qualifiers dentro de un nodo así no se detectan y darían un LUT incorrecto.
La detección se basa en los nombres de efectos visibles en Resolve; no es un análisis completo de la imagen. Un LUT 65³ es una aproximación: pueden aparecer pequeñas diferencias en colores extremos o junto a transiciones abruptas. La aplicación no afirma que un LUT se vea idéntico al DRX; compáralos con tu propio material.

## 8. Si algo falla
![failed]
- «DaVinci Resolve no está abierto»: abre Resolve Studio e inténtalo de nuevo.
- «Resolve no acepta la conexión»: activa el scripting externo (sección 2).
- «Efectos que faltan en este Mac»: instala los efectos OFX del DRX y abre el DRX de nuevo.
- «El archivo DRX parece dañado»: expórtalo de nuevo desde Resolve.
- «El resultado del render es degenerado»: normalmente medios sin conexión o un nodo que destruye la imagen; no se escribe ningún LUT.

## 9. Actualizaciones, privacidad, desinstalación
La aplicación busca actualizaciones al iniciar y verifica la firma, la suma de control y la versión del paquete antes de instalar. Tus archivos DRX, LUT y datos personales no salen de tu Mac; la única conexión de red es la comprobación de actualizaciones. Se guarda un registro local en ~/Library/Logs/DRXtoLUT.log; desde Ajustes puedes exportar un paquete de diagnóstico redactado que envías tú si quieres. Ajustes > «Desinstalar la aplicación por completo» elimina la aplicación y sus datos.
DRX to LUT es un proyecto independiente con licencia MIT, ofrecido «tal cual», y no está afiliado a Blackmagic Design. Incluye un runtime de Python 3.12; ver OPEN_SOURCE_NOTICES.md. Código fuente e incidencias: https://github.com/gordasgdc/drx-to-lut
