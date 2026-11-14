# BROKEN DREAMS — Lobby listo para abrir

## Abrir el proyecto

1. Descarga `Broken-Dreams-Lobby.rbxlx` o descomprime este ZIP.
2. Abre Roblox Studio.
3. Usa **Archivo → Abrir desde archivo** y selecciona `Broken-Dreams-Lobby.rbxlx`.
4. El lobby ya está construido en `Workspace > BrokenDreamsLobby`. No necesitas Command Bar ni ejecutar un instalador.
5. Para recorrerlo, pulsa **Play**. Guarda tu copia con **Archivo → Guardar como**.

El archivo .rbxlx contiene el escenario, Lighting, SpawnLocation, paneles, interfaz de temporizador y scripts de conexión futura. Se ha conservado el lobby preparado en esta conversación. BROKEN DREAMS es independiente de FORGOTTEN; esta entrega no contiene ni modifica sistemas de FORGOTTEN.

## Importaciones manuales

**No se requiere importar accesorios, meshes ni texturas para visualizar y explorar este lobby.** La geometría y los materiales nativos están incluidos. No se han inventado AssetIds.

Los seis retratos definitivos y la imagen del próximo mapa quedan pendientes de tus originales. Para mostrarlos en el futuro, tendrás que subir esas imágenes a Roblox y colocar sus IDs reales mediante los atributos o la API. Eso no impide abrir el escenario actual.

`Broken-Dreams-Lobby.rbxmx` es una copia opcional del modelo 3D del escenario para importarlo en otro lugar. Ese modelo aislado no contiene los scripts y servicios completos del proyecto; para esta entrega abre el **.rbxlx**.

## Qué incluye

- Sala de 72 × 60 studs con suelo, cubierta y cortinajes 3D.
- Malicia al fondo a la izquierda y Próximo mapa al fondo a la derecha.
- Seis cuadros para Rayman, Globox, Grand Minimus, Barbara, Murfy y Ly.
- Rincón de skins, alfombra central, faroles, decoración y entrada con SpawnLocation.
- 3.550 piezas ancladas, 12 luces locales y partículas discretas.
- Tercera persona y movimiento normal de Roblox.
- Sin botón Jugar, sin portal obligatorio y sin un sistema de partidas activo.

El temporizador muestra `—:—` hasta que un futuro sistema servidor actualice el estado. `LobbyWaitSeconds = 45` es únicamente un valor configurable de ejemplo y no pone en marcha una cuenta atrás.

## Conexiones para más adelante

En `ReplicatedStorage > BrokenDreamsLobbyState` están los atributos de estado, y en `Portraits` los campos vacíos de los seis supervivientes.

Desde un Script servidor, o desde Command Bar en contexto Server durante Play:

```lua
local api = require(game.ServerScriptService.BrokenDreamsLobbyAPI)
api.SetCountdown(75) -- muestra 01:15; no inicia partidas
api.SetCountdown(-1)
```

Para imágenes, sustituye ID_REAL por un ID numérico válido que tengas permiso para usar:

```lua
api.SetNextMap("Nombre del mapa", "rbxassetid://ID_REAL")
api.SetPortrait("Rayman", "rbxassetid://ID_REAL")
```

La API de Malicia devuelve obligatoriamente el máximo de los valores que le suministra el servidor. Para un empate usa el menor UserId como criterio técnico determinista; se puede adaptar cuando decidas esa regla. No ejecuta una elección aleatoria, no asigna roles y no inicia partidas.

## Validaciones realizadas

- Serialización a .rbxlx con Lune 0.11.1 / rbx-dom y lectura posterior del mismo archivo.
- Conservación de 3.550 piezas, scripts, atributos y SpawnLocation.
- XML válido, referencias internas resueltas y objetos con identificadores únicos.
- Nueve SurfaceGuis, seis espacios de retratos y ausencia de botones Jugar.
- Compilación de los scripts extraídos del archivo final con el compilador oficial Luau.
- Comprobaciones geométricas previas y pruebas aisladas de la API.
- Integridad ZIP mediante CRC y hashes SHA-256.

**No se ejecutó Roblox Studio en este entorno Linux.** Por tanto, Play, el comportamiento del Humanoid, la cámara, la presentación real de las interfaces, el multijugador y el rendimiento siguen pendientes de prueba dentro de Studio. La validación del archivo no equivale a una prueba del motor.

Las imágenes en `vistas` son renders externos de la geometría, no capturas de Roblox Studio. Se conserva la distribución de la referencia; los adornos y las telas son aproximaciones con piezas nativas, no una reproducción artística exacta.

## Comprobar en Studio

Ejecuta `herramientas/VERIFICAR_LOBBY.luau` en Command Bar para revisar estructura y rutas. Después prueba WASD, salto, zoom, aparición en la entrada y dos clientes. Las cámaras de inspección se encuentran en `herramientas/CAMARAS_STUDIO.luau`; usa `restaurar` al finalizar.

Los scripts y datos fuente se incluyen para revisión. No necesitas instalar Python, Lune ni Blender para abrir este proyecto en Roblox Studio.
