# BROKEN DREAMS — Lobby con bosque exterior

## Abrir

1. Descarga el archivo `Broken-Dreams-Lobby-Bosque.rbxlx` o descomprime este ZIP.
2. En Roblox Studio elige **Archivo → Abrir desde archivo** y selecciona ese .rbxlx.
3. El interior y el bosque ya están construidos. Pulsa **Play** para recorrerlos y guarda tu copia.

No necesitas ejecutar un instalador ni importar accesorios, meshes o texturas para ver esta entrega. Se utilizan piezas, materiales y recursos de partículas incorporados en Roblox. Los retratos y las imágenes definitivas de mapas siguen pendientes de tus originales.

## Cambios de esta versión

- Bosque estilizado de **75 árboles**, con follaje, algunos árboles secos, hierba, rocas con musgo, raíces y troncos caídos.
- Terreno exterior de unos **178 × 166 studs** alrededor de la carpa de 72 × 60.
- Un sendero de tierra continuo rodea la carpa y conecta con la entrada y tres claros.
- Árboles densos, raíces y taludes rocosos visibles forman el límite natural. El acceso central permanece libre.
- Entrada ampliada con plataforma de madera, arco, toldo envejecido, banderines, faroles, cajas y barriles.
- Carteles viejos, hongos luminosos y pequeños cristales mágicos.
- Niebla suave mediante Atmosphere y cuatro emisores discretos situados hacia los bordes del bosque.
- Área de cámara y HUD extendida para que la espera siga visible fuera de la carpa.

Se trabajó sobre el .rbxlx publicado en el commit `8e3b94042fab518854c0976a617b0a7a0c3f2870`. Se conservaron **3.549 piezas originales** sin modificar sus posiciones, tamaños, materiales ni colisiones. Se retiró únicamente `EntrySafetyBoundary`, el antiguo límite transparente detrás de la entrada, para permitir salir. Los dos scripts de servidor se conservan íntegros. En el cliente solo se amplió la comprobación del área del lobby.

Las piezas nuevas están en `Workspace > BrokenDreamsLobby > ForestExterior`. Allí puedes ajustar árboles, senderos, entrada, señales y decoración. La niebla global está en `Lighting > BD_ForestAtmosphere`.

Los límites del HUD se configuran en `ReplicatedStorage > BrokenDreamsLobbyState`, mediante `LobbyBoundsMin` y `LobbyBoundsMax` (coordenadas relativas a Origin).

## Qué se conserva

Los cuadros de Malicia y Próximo mapa, la galería de seis supervivientes, el rincón de skins, el temporizador preparado, el SpawnLocation y las conexiones futuras siguen en el proyecto. No se añadieron sistemas de partidas, personajes jugables, botones Jugar ni cambios en las reglas.

`ForestExterior.rbxmx` es una copia opcional del exterior para editarlo o reutilizarlo. Por sí solo no actualiza la niebla global, el HUD ni el acceso del proyecto anterior. Para usar esta entrega completa, abre el **.rbxlx**.

## Comprobaciones

- Exportación y lectura posterior del lugar con Lune 0.11.1 / rbx-dom.
- 5.580 piezas ancladas totales, 17 luces locales totales y referencias XML válidas.
- Conservación de las 3.549 piezas originales restantes y de ambos scripts de servidor.
- Comprobaciones analíticas de 948 posiciones de avatar en senderos, entrada y claros, sin colisiones.
- 720 comprobaciones radiales del límite natural, sin huecos en los taludes sólidos.
- Compilación Luau de los scripts guardados y del verificador.
- CRC del ZIP y hashes SHA-256 de los archivos de entrega.

**No se ha ejecutado Roblox Studio en este entorno.** Las comprobaciones geométricas no sustituyen las pruebas de Humanoid, saltos, cámara, móviles, multijugador ni rendimiento del motor. Ejecuta `herramientas/VERIFICAR_BOSQUE.luau` en Command Bar y después prueba Play.

Los renders incluidos en `vistas` se generaron fuera de Roblox Studio a partir de la misma geometría. Son vistas de revisión, no capturas de una prueba en Studio; los materiales, la luz y la niebla pueden variar en Roblox.

## Archivos

- `.rbxlx`: proyecto completo listo para abrir.
- `.rbxmx`: exterior opcional como modelo importable.
- `fuentes`: datos geométricos y código utilizado para la ampliación; se incluyen para revisión técnica, no son necesarios para abrir el proyecto.
- `herramientas/VERIFICAR_BOSQUE.luau`: revisión dentro de Studio.
- `VALIDACION_BOSQUE.json`: informe de comprobaciones locales.
- `SHA256SUMS.txt`: integridad de los contenidos del ZIP.
