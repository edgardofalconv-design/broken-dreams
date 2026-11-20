# BROKEN DREAMS — rondas multijugador, versión de prueba

Esta rama entrega el sistema de partidas sobre el **lobby y bosque existentes**, con una **arena provisional separada y exclusiva de Studio**. The Forgotten Glade sigue pendiente de construcción como primer mapa oficial.

## Archivos

- [Proyecto completo para Roblox Studio](dist/Broken-Dreams-Partidas.rbxlx)
- [ZIP con proyecto, respaldo, scripts, modelo importable y guía](dist/Broken-Dreams-Partidas-Entrega.zip)
- [Guía para abrir, probar e integrar](GUIA_PARTIDAS.md)
- [Comprobaciones locales y limitaciones](VALIDACION_PARTIDAS.json)
- [Lista de pruebas pendientes en Studio](PRUEBAS_STUDIO.md)
- [Código fuente](src)

Descarga preferentemente el ZIP y extráelo. Abre `Broken-Dreams-Partidas.rbxlx` en Studio mediante **Archivo → Abrir desde archivo**. No necesitas importar recursos adicionales en ese archivo. Usa **Test → Server & Clients**, con tres jugadores, para probar también la reanimación. No hay botón Jugar.

Incluye intermedio automático, Malicia máxima obligatoria, selección única de seis supervivientes, ronda de 5:55, dos vidas/reanimación, bonificación de +10 por eliminación final, cuadro de escape a 1:20, LMS de 3:37, resultados, espectador, regreso y herramientas solo Studio. No incluye habilidades definitivas, economía, modelos ni música aún no proporcionados.

La comparación del archivo confirma **5.731 instancias originales conservadas, incluidas 5.580 piezas**. El único script original modificado es el controlador del HUD; los tableros siguen conectados a su API existente. Se incluyen **43 pruebas locales de lógica/adaptadores**, compilación Luau y validación de XML y marcadores de la arena.

**No se ejecutó Roblox Studio en el entorno de desarrollo.** La física, la recuperación de Humanoid, los prompts con latencia, la interfaz móvil y la sesión multicliente siguen pendientes de las pruebas descritas en la guía. La arena y las herramientas están desactivadas en servidores públicos.

La rama se basa en `delivery/lobby-bosque-20261114`. Las versiones anteriores y la rama principal se conservan. No contiene cambios en FORGOTTEN.
