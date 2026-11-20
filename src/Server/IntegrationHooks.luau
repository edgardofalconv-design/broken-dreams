-- Módulo SOLO servidor. Conectar aquí datos/economía existentes cuando se proporcionen.
-- No hay incremento, reinicio, premios ni almacenamiento inventados.
local Hooks={}
function Hooks.ReadMalicia(_player) return nil end -- nil usa GameConfig.InitialMalicia por sesión
function Hooks.OnResult(_player,_result,_roundKey)
 -- Una llamada por usuario/ronda en este servidor. Para guardar premios:
 -- usar UpdateAsync y deduplicar por roundKey ANTES de aplicar el premio.
end
return Hooks
