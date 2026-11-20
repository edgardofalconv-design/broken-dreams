# BROKEN DREAMS — primera versión del sistema de partidas

Esta entrega conserva el lobby publicado y añade un sistema de rondas y una **arena provisional, solo para pruebas en Roblox Studio**. **The Forgotten Glade todavía no está construido.** El bosque alrededor de la carpa continúa siendo parte del lobby.

El código y los archivos se validaron localmente. No se abrió Roblox Studio ni se ejecutó una sesión multicliente en este entorno. No se considera una versión de producción validada.

## Abrir la entrega

1. Descarga y extrae `Broken-Dreams-Partidas-Entrega.zip`.
2. Abre Roblox Studio → **Archivo → Abrir desde archivo** → `Broken-Dreams-Partidas.rbxlx`.
3. Guarda una copia con otro nombre. El ZIP incluye el proyecto anterior completo en `backups/Broken-Dreams-Antes-Partidas.rbxlx`.
4. Para este archivo completo **no necesitas importar ningún accesorio, textura, audio ni modelo adicional**.
5. La arena está en `ServerStorage/BrokenDreamsMaps/BD_TestArena`. Es normal que no aparezca junto al lobby en edición: el servidor clona esa arena en Workspace al preparar una ronda de Studio y elimina únicamente esa copia al terminar.

No hay un botón Jugar. El intermedio comienza automáticamente al haber al menos dos jugadores y un mapa disponible.

## Probar con varios clientes

En la pestaña **Test / Prueba**, usa el modo **Server & Clients / Servidor y clientes**, elige **3 jugadores** e inicia la simulación local. En versiones anteriores de Studio aparece como **Local Server → Players → Start**. Un solo cliente permanecerá esperando: es intencionado.

Con tres clientes habrá un asesino y dos supervivientes. Dos clientes bastan para probar el ciclo y el LMS manual; se necesitan al menos tres para reanimar a un compañero.

1. Espera el intermedio de 30 segundos; después hay 15 segundos provisionales de selección.
2. Acércate a los cuadros originales y usa su interacción. En PC es la tecla que muestre el prompt; en móvil toca la interacción. Antes de la selección se guarda una preferencia. Durante la selección se reserva un personaje único por ronda.
3. El servidor teletransporta únicamente a los participantes a la arena. Los jugadores adicionales esperan en el lobby.
4. El asesino, identificado como **RAY.X · PROVISIONAL**, recibe la herramienta **STUDIO · Daño de prueba**. Equípala y actívala cerca de un superviviente, a menos de 12 studs y sin paredes entre ambos.
5. La primera aplicación de 100 de daño incapacita. Otro superviviente vivo debe acercarse y mantener **Reanimar**. El servidor exige 4 segundos y comprueba continuamente distancia, estado y línea de visión. El prompt añade 0,2 segundos de margen visual para la entrega de eventos.
6. Tras reanimar, la siguiente caída elimina. Una eliminación atribuida al asesino añade 10 segundos solo en ronda normal. Si esta eliminación activa LMS, el tiempo se sustituye por 217, como exige esa transición.
7. Cuando queden 80 segundos, el cuadro se abre en un marcador validado. Entra en su superficie luminosa para escapar. No necesita pulsar un botón. El asesino y los incapacitados no pueden usarlo.
8. Los resultados duran 8 segundos provisionales. Se restaura el avatar guardado antes de la ronda y todos regresan al lobby original. Comienza otro ciclo.

Durante las pruebas abre **View → Output / Vista → Salida** tanto en servidor como en clientes. Los resultados observados en esas ventanas deben registrarse en `PRUEBAS_STUDIO.md`; esa lista no está marcada como superada.

## Herramientas de desarrollo

Solo existen cuando `RunService:IsStudio()` es verdadero y `GameConfig.StudioToolsEnabled` está activado. No hay un RemoteEvent de administración. La herramienta de daño tampoco se entrega en servidores públicos.

En la ventana del **servidor** de la simulación abre la Command Bar. No uses la ventana de un cliente para estos comandos:

```lua
local p = game.Players:GetPlayers()
for _, player in p do print(player.Name, player.UserId) end
```

Sustituye `USER_ID` por el número mostrado, que puede ser negativo en Studio. Cada línea siguiente es independiente:

```lua
-- Ver estado, roles y resultados en Output:
print(game.ServerStorage.BrokenDreamsDebug:Invoke("Status"))
-- Intermedios siguientes de 3 segundos:
game.ServerStorage.BrokenDreamsDebug:Invoke("Intermission", nil, 3)
-- Fijar Malicia temporal antes de elegir roles:
game.ServerStorage.BrokenDreamsDebug:Invoke("Malicia", USER_ID, 25)
-- Forzar un asesino de prueba: le asigna máximo actual + 1 de Malicia.
game.ServerStorage.BrokenDreamsDebug:Invoke("Killer", USER_ID)
-- Terminar el intermedio actual; requiere mapa y dos jugadores:
game.ServerStorage.BrokenDreamsDebug:Invoke("Start")
-- Primera caída o daño sobre un superviviente vivo:
game.ServerStorage.BrokenDreamsDebug:Invoke("Down", USER_ID)
game.ServerStorage.BrokenDreamsDebug:Invoke("Damage", USER_ID, 25)
-- Revivir un incapacitado para aislar pruebas de la segunda vida:
game.ServerStorage.BrokenDreamsDebug:Invoke("Revive", USER_ID)
-- Abrir la salida, sin crear otra si ya existe:
game.ServerStorage.BrokenDreamsDebug:Invoke("Escape")
-- LMS manual, solo si queda exactamente un superviviente ALIVE:
game.ServerStorage.BrokenDreamsDebug:Invoke("LMS")
-- Acortar el tiempo de la ronda actual, por ejemplo a 81 segundos:
game.ServerStorage.BrokenDreamsDebug:Invoke("Time", nil, 81)
-- Cancelar la ronda activa y probar resultados/regreso:
game.ServerStorage.BrokenDreamsDebug:Invoke("End")
```

El daño de prueba de los comandos se atribuye al asesino actual. Un reset o daño ambiental no concede segundos al asesino. No son habilidades definitivas de RAY.X.

## Qué se conservó y qué cambió

Se inspeccionó la entrega de GitHub `0bac0d0079bb7dd3c896c6313e470c42d3ac7bdb`: carpa, bosque exterior, galería de seis personajes, cuadros de Malicia y próximo mapa, SpawnLocation y HUD. Había dos scripts de servidor —un Script de actualización de tableros y un ModuleScript API— y un LocalScript del HUD. No había mapas independientes ni sistema de rondas.

Las **5.580 piezas originales** conservan CFrame, tamaño, material, color, transparencia y colisiones. No se tocó Lighting, la carpa, el bosque ni su decoración. Los dos scripts originales del servidor conservan exactamente sus fuentes. La copia previa se incluye completa, con SHA-256.

El único script existente modificado es `StarterGui/BrokenDreamsLobbyHUD/LobbyHUD`: ahora conecta el mismo `Panel/Heading` y `Panel/Time` al estado sincronizado. Se amplía ese ScreenGui con información, avisos, resultados y espectador; no se agrega otro temporizador ni un botón PLAY. `LobbyWaitSeconds` pasa de un valor sin usar de 45 a 30; la fuente efectiva de configuración es `Shared/GameConfig`.

Los cuadros siguen usando `BrokenDreamsLobbyState` y el servidor original:

- `MaliciaName`, `MaliciaUserId`, `MaliciaValue`: líder o empate durante espera; asesino elegido durante la ronda.
- `NextMapName`, `NextMapImage`: mapa seleccionado y recurso opcional.
- `Portraits`: se conservan los campos vacíos para los retratos originales que proporcionarás.
- Cada cuadro de personaje recibe un ProximityPrompt al ejecutar el juego. Su texto inferior indica la reserva durante la selección.

La antigua función `BrokenDreamsLobbyAPI.GetHighestMalice` se conserva por compatibilidad, pero **el controlador nuevo no la utiliza para elegir roles**. La selección efectiva está en `RoundCore.ChooseKiller`: mayor Malicia estricta; entre máximos, quien menos recientemente fue asesino en esta sesión; si persiste el empate, sorteo uniforme solo entre esos empatados. El tablero muestra EMPATE hasta que se resuelve, sin afirmar un ganador antes de tiempo.

## Organización del código

`ReplicatedStorage/BrokenDreams/Shared`: GameConfig, RoundStates, CharacterRegistry, MapRegistry.

`ReplicatedStorage/BrokenDreams/Remotes`: Request, Snapshot, Notice. El cliente solo solicita sincronización, selección y comienzo/cancelación de reanimación. El servidor valida tipo, frecuencia, fase, identidad, distancia y estado. No acepta valores de Malicia, salud, tiempo, vidas, roles ni resultados del cliente.

`ServerScriptService/BrokenDreams`: RoundService, RoundCore, MaliciaService, MapService, SpawnService, AvatarService, HealthService, ReviveService, EscapeService, ResultsService, RateLimiter e IntegrationHooks. Roles, reservas y transición LMS viven en el núcleo para que no haya varias máquinas de estados compitiendo.

`ReplicatedStorage/BrokenDreams/Client`: RoundUIController, CharacterSelectionController y MusicController, llamados por el LocalScript del HUD existente. El cliente interpola el tiempo usando `Workspace:GetServerTimeNow()` y el plazo del servidor. No decide el fin de la ronda.

`ServerStorage/BrokenDreamsMaps/BD_TestArena`: únicamente el mapa de prueba. Las plantillas y módulos del ZIP coinciden con los del `.rbxlx`.

## Reglas provisionales y límites conocidos

- Intermedio 30 s, selección 15 s, resultados 8 s, reanimación 4 s con 50 de salud y sangrado de 45 s: configurables. `BleedoutSeconds=false` desactiva el sangrado, aunque podría dejar una incapacitación pendiente hasta el fin de la ronda.
- Ronda normal 355 s; LMS 217 s; salida a 80 s; +10 por eliminación final atribuida al asesino en ronda normal.
- Los incapacitados cuentan como participantes. LMS automático requiere que originalmente hubiera al menos dos supervivientes y ahora quede solo uno vivo; no fuerza LMS en una ronda iniciada 1v1. Una vez activado no se repite.
- El máximo es un asesino y seis supervivientes. Los excedentes tienen prioridad de cola en el siguiente ciclo. El máximo de Malicia se elige antes de limitar esa cola.
- Sin datos conectados, Malicia inicial es 0 por sesión. No hay una fórmula de ganancia/pérdida, DataStore ni premios inventados. `IntegrationHooks.ReadMalicia` permite conectar datos existentes. `OnResult` se llama una vez por jugador/ronda; una futura economía persistente debe deduplicar también en DataStore por la clave de ronda proporcionada.
- Timeout es derrota provisional para quienes no escaparon; opción `DRAW` disponible. Si el asesino abandona o se pierde su avatar, los supervivientes todavía participantes ganan por abandono, sin marcarlos falsamente como ESCAPED. Un resultado con escapes y derrotas es MIXED.
- Los avatares provisionales son copias del avatar original del jugador. RAY.X recibe una identificación y un Highlight provisional. Se guarda el avatar inicial para restaurarlo al volver.
- La salud autoritativa reside en `RoundCore`. `Humanoid.Health` se refleja con mínimo 1 durante DOWNED. Daño externo de Humanoid se trata como ambiental; si el motor ya produjo Died/reset se recupera el avatar sin regalar vidas. **Este puente de Humanoid requiere validación real en Studio**, junto con animaciones, controles móviles, cámara y latencia de los prompts.
- El juego público no carga la arena de prueba ni habilita las herramientas. Hasta construir/importar un mapa oficial válido, permanecerá esperando. La primera versión jugable solicitada está orientada a simulaciones locales en Studio.
- No hay habilidades definitivas, generadores, estamina, modelos o audios inventados. No se afirma que el sistema esté libre de errores del motor antes de sus pruebas en Studio.

## Añadir The Forgotten Glade y otros mapas

1. Construye/importa el mapa real como un **Model independiente**, por ejemplo `ServerStorage/BrokenDreamsMaps/The Forgotten Glade`. Puede permanecer en Workspace si ya está allí; MapService no mueve su geometría. Las plantillas de ServerStorage se clonan preservando sus coordenadas.
2. Dale el atributo de texto `BDMapId = forgotten_glade`. Coloca su geometría lejos del rectángulo del lobby (la arena de ejemplo está centrada en X=400). No incluyas el lobby en el modelo.
3. Dentro del modelo añade un Part llamado `PlayBounds`, Anchored=true, CanCollide=false, CanQuery=false, CanTouch=false, Transparency=1. Su CFrame y Size deben delimitar el volumen jugable real.
4. Añade una carpeta `RoundSpawns`, con Parts `Killer`, `Escape` y una carpeta `Survivors` con `Survivor01` a `Survivor06`. Todos Anchored=true, CanCollide=false, CanQuery=false, CanTouch=false, Transparency=1. Ponlos aproximadamente sobre el suelo, en lugares alcanzables a pie.
5. Deja al menos 5 studs entre supervivientes, 24 entre asesino y supervivientes, y un volumen libre de 9×10×6 studs para el cuadro. Cada marcador necesita suelo bajo su centro y sus cuatro esquinas; la altura del raycast y la tolerancia de inclinación se verifican en SpawnService. El lugar debe estar dentro de PlayBounds y fuera del lobby.
6. `MapRegistry` ya tiene `forgotten_glade` habilitado. Una entrada sin modelo válido no se selecciona. Los otros cuatro mapas están registrados pero deshabilitados; habilítalos cuando existan con sus marcadores. Puedes deshabilitar `round_test` cuando termine la fase de pruebas.
7. Las coordenadas no se inventan automáticamente. La validación detecta suelo, pendiente, espacio y separación, pero **no demuestra que toda la ruta hasta la salida sea transitable**: compruébala caminando con varios clientes. Si falla un punto, la ronda se cancela y vuelve al lobby.

Los modelos de respaldo pueden llevar `BD_IgnoreMapDiscovery=true` en un antepasado para excluirlos de la búsqueda. No dupliques un mismo BDMapId entre dos mapas activos.

## Conectar modelos y música posteriormente

En `ServerStorage` crea `BrokenDreamsCharacters`. Cada modelo autorizado debe incluir un Humanoid vivo, HumanoidRootPart, rig y animaciones compatibles con Roblox. En `CharacterRegistry.Survivors[nombre].ModelName` escribe su nombre; para RAY.X utiliza `CharacterRegistry.Killer.ModelName`. Vacío mantiene el avatar provisional. AvatarService es el punto de extensión para un rig especial; prueba cámara, altura y colisión si sus dimensiones superan las del avatar estándar.

Pon IDs reales y autorizados en `LMSMusicId` de cada superviviente, con formato `rbxassetid://123...`. No hay ningún ID ficticio. El nombre de la canción de Rayman ya es **THE LAST DREAM**. `GameConfig.NormalMusicId` configura música normal. Sin ID, el sistema permanece en silencio y LMS sigue funcionando. Al regresar o mostrar resultados se detiene la música.

Para futuras habilidades, llama desde código de servidor a la API de HealthService usada por RoundService; valida rol, objetivo, alcance, línea de visión y frecuencia antes de aplicar daño. No uses un RemoteEvent que acepte del cliente la cantidad de daño o el resultado.

## Integrarlo en otro proyecto local sin sustituir su mapa

Esta opción solo hace falta si tu lugar local tiene contenido más reciente que el archivo entregado:

1. Guarda **todo** el lugar local con otro nombre antes de instalar.
2. En modo edición, inserta `Broken-Dreams-Sistema-Partidas.rbxmx` en Workspace mediante **Insert from File / Insertar desde archivo**.
3. Abre `INSTALAR_EN_PROYECTO_EXISTENTE.luau` en un editor, copia su contenido entero y ejecútalo en la Command Bar de Studio.
4. El instalador verifica los nombres del lobby original, guarda el controlador previo del HUD y su estado en ServerStorage, añade servicios y arena, y actualiza solamente el controlador del HUD. No toca geometría ni iluminación.
5. Si ya hay una carpeta `BrokenDreams` o `BrokenDreamsMaps`, se detiene antes de escribir. Esa situación requiere adaptar la integración al sistema real existente, no borrar esas carpetas.

La ruta principal recomendada para esta entrega es abrir el `.rbxlx` completo; no ejecutes el instalador sobre él porque ya contiene el sistema.
