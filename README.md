# BROKEN DREAMS — cuenta regresiva automática

[Descargar ZIP completo](dist/Broken-Dreams-Contador-Entrega.zip) · [Abrir proyecto .rbxlx](dist/Broken-Dreams-Contador.rbxlx) · [Guía de pruebas e integración](GUIA_CONTADOR.md)

Sobre el proyecto existente: con dos jugadores inicia una cuenta de 30 segundos en el mismo cartel del HUD. Si queda uno, se cancela y muestra **ESPERANDO JUGADORES...**. Al llegar a **00:00**, emite una señal interna de servidor una sola vez; no carga mapas ni teletransporta.

No se altera Malicia, la carpa, el bosque, los cuadros, el tablero de próximo mapa ni Lighting. Se conservan el sistema anterior y la arena de pruebas, desactivando su inicio automático mediante `LobbyCountdownOnly=true`.

Para otra prueba, en la Command Bar del servidor durante Play:

```lua
game.ServerScriptService.BrokenDreams.Signals.RestartLobbyCountdown:Invoke()
```

El ZIP incluye el respaldo anterior, todas las fuentes, un parche para Command Bar y la guía. Las 11 pruebas locales nuevas y 43 anteriores pasan. **Roblox Studio y la prueba multicliente no se ejecutaron en este entorno.** Consulta el informe `VALIDACION_CONTADOR.json`.

Esta rama conserva las entregas anteriores. La documentación `GUIA_PARTIDAS.md` describe el ciclo previo; para la configuración activa de este archivo utiliza **GUIA_CONTADOR.md**.
