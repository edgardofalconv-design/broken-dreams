# BROKEN DREAMS — contador automático del lobby

Se trabajó sobre la entrega `a109fbee39af1c70680b4bc618eb4cb7e09958c1`, sin reconstruir el lugar. The Forgotten Glade sigue sin construirse. La arena provisional de la entrega anterior se conserva, pero **no se carga en este modo**.

## Abrir y probar

1. Extrae el ZIP y abre `Broken-Dreams-Contador.rbxlx` con **Roblox Studio → Archivo → Abrir desde archivo**. No necesitas importar recursos adicionales.
2. Abre **Test → Server & Clients / Servidor y clientes**. Con un cliente aparece `ESPERANDO JUGADORES...`; el campo del tiempo queda `—:—`.
3. Añade un segundo cliente usando la simulación local. También puedes reiniciar la simulación con dos clientes. El contador inicia automáticamente en `00:30`.
4. Revisa ambos clientes. Reciben el mismo valor entero calculado por el servidor; no tienen un contador local independiente. La entrega de mensajes depende de la latencia de red y no se ha medido aquí en Studio.
5. Durante la cuenta, cierra un cliente: si queda uno, se cancela. Al volver a haber dos, empieza desde 30, sin continuar una cuenta vieja.
6. Deja que llegue a cero. Se mantiene `00:00`, se emite una única solicitud de inicio y nadie es teletransportado. No vuelve a contar indefinidamente mientras sigan esos jugadores; usa el reinicio para otra prueba. Si baja de dos y vuelve a subir, empieza otro ciclo.

El cartel encontrado en esta versión está en `StarterGui/BrokenDreamsLobbyHUD/Panel`: `Heading` es el título y `Time` es el campo inferior. **No se encontró otro cartel físico 3D con ese texto.** Se utilizan exactamente esos elementos existentes; sus propiedades visuales, posición, colores y decoración no se cambian. No se crea otro ScreenGui ni otro cartel.

## Ver la señal interna

Durante la simulación, cambia a la ventana/contexto del **servidor** y abre la Command Bar. Conecta este observador antes de finalizar la cuenta:

```lua
game.ServerScriptService.BrokenDreams.Signals.RoundStartRequested.Event:Connect(function(countdownId, completedAt)
    print("BROKEN DREAMS: solicitud de inicio", countdownId, completedAt)
end)
```

Ejecuta el observador una sola vez; si lo ejecutas varias veces tendrás varios observadores imprimiendo la misma señal. El contador produce un único evento por ciclo.

Después de terminar puedes consultar la última solicitud sin haber conectado el observador:

```lua
print(game.ReplicatedStorage.BrokenDreams.RoundState:GetAttribute("LastStartRequestId"))
```

`RoundStartRequested` es un **BindableEvent de servidor** con argumentos `(countdownId, completedAt)`. No es un RemoteEvent que un cliente pueda disparar. No tiene consumidores de mapas conectados en esta entrega. Un futuro servicio de mapas podrá suscribirse y validar su mapa antes de empezar una ronda.

## Reiniciar

Desde la Command Bar del **servidor en ejecución**:

```lua
game.ServerScriptService.BrokenDreams.Signals.RestartLobbyCountdown:Invoke()
```

Con dos jugadores inicia 30 segundos nuevos. Con menos de dos permanece esperando. Funciona tanto durante una cuenta como después de llegar a cero. No cambia la Malicia ni requiere un botón de interfaz. No uses el comando antiguo `BrokenDreamsDebug:Invoke("Start")`, que pertenece al flujo de partidas con mapa.

## Cambios de código

| Archivo lógico | Cambio |
| --- | --- |
| `Shared/GameConfig` | `LobbyCountdownOnly=true`: habilita esta etapa sin cargar mapas. Se conservan mínimo 2 y duración 30. |
| `Shared/RoundStates` | Añade `ROUND_START_REQUESTED` para sostener 00:00 después del evento. |
| `Server/RoundCore` | Integra inicio, cancelación, final único y reinicio en la máquina de estados existente. |
| `Server/RoundService` | Conecta los Bindables, publica el tiempo del servidor y evita cargar mapas en este modo. |
| `Client/RoundUIController` | Reutiliza Heading/Time; muestra espera, 00:09 y el entero publicado por servidor. |
| `Shared/TimerFormat` — nuevo | Formato único `mm:ss`. |

El servidor continúa siendo el único dueño del plazo. El guard existente `RoundState.Running` evita controladores duplicados; no se añade otro Script que cuente en paralelo.

Se conservan sin cambios `MaliciaService`, `IntegrationHooks`, `BrokenDreamsLobbyAPI`, `BrokenDreamsLobbyServer` y la función de elección por mayor Malicia en RoundCore. El tablero de Malicia sigue actualizándose. No se elige asesino ni se altera Malicia al terminar este contador. El tablero de próximo mapa conserva su contenido: este modo no llama al actualizador de mapas.

No se modifican geometría, iluminación, carpa, bosque, cuadros, mapas almacenados ni estilos de la interfaz. Las modificaciones del archivo son únicamente cinco fuentes de scripts y la incorporación de TimerFormat.

Para recuperar más adelante el ciclo de partidas completo de la entrega anterior, cambia `LobbyCountdownOnly=false` en modo edición y vuelve a iniciar la simulación. En ese modo vuelve a requerirse un mapa válido. No conectes un segundo controlador de rondas en paralelo a RoundService.

## Integrar en tu copia local si tiene cambios adicionales

El ZIP incluye `APLICAR_CONTADOR_COMMAND_BAR.luau`. Guarda primero una copia de tu lugar, detén Play y ejecuta el contenido completo de ese archivo en la Command Bar. Comprueba que las cinco fuentes originales correspondan a la versión de partida; si difieren, el instalador se detiene antes de escribir para conservar tus cambios. Si coinciden, guarda sus fuentes previas en ServerStorage y aplica únicamente este ajuste. No lo ejecutes sobre el `.rbxlx` entregado, que ya lo incluye.

## Pruebas y límites

Se ejecutaron 11 pruebas locales de cuenta regresiva, las 34 pruebas anteriores del núcleo y las 9 pruebas de adaptadores con dobles locales. Cubren mínimo de jugadores, ausencia de mapa, cancelación incluso en el tick de cero, consumo único del evento, reinicios, formato, conservación de Malicia y ausencia de transición hacia mapas. El test de publicación comprueba que todos consumen el mismo valor, **no una red real**.

También se compilaron las fuentes Luau y se compararon los archivos nativos para confirmar que los cambios se limitan a los declarados. El ZIP incluye `backups/Antes-Contador.rbxlx`, copia exacta del proyecto previo.

**No se abrió Roblox Studio en este entorno.** Quedan pendientes las seis comprobaciones solicitadas en una sesión real, en particular entrega de BindableEvent, latencia entre clientes y visibilidad del HUD. Usa los pasos de arriba y revisa Output del servidor y de cada cliente; las pruebas locales no se presentan como pruebas de Studio aprobadas.
