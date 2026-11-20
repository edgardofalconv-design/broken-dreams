-- COMMAND BAR DE STUDIO, en modo edición. Primero guarda tu lugar con otro nombre.
-- Inserta Broken-Dreams-Sistema-Partidas.rbxmx en Workspace y ejecuta este archivo completo.
assert(not game:GetService("RunService"):IsRunning(),"Detén Play antes de instalar")
local RS=game:GetService("ReplicatedStorage")
local SSS=game:GetService("ServerScriptService")
local SS=game:GetService("ServerStorage")
local package=workspace:FindFirstChild("BrokenDreamsRoundPackage")
assert(package and package:FindFirstChild("ServerModules") and package:FindFirstChild("BrokenDreams") and package:FindFirstChild("HUDSource"),"Inserta primero el paquete .rbxmx")
assert(not RS:FindFirstChild("BrokenDreams") and not SSS:FindFirstChild("BrokenDreams"),"Ya existe un sistema BrokenDreams: no se sobrescribirá")
local lobby=workspace:FindFirstChild("BrokenDreamsLobby")
assert(lobby and lobby:FindFirstChild("ForestExterior") and lobby:FindFirstChild("CharacterGallery"),"No se encontró el lobby original completo")
assert(RS:FindFirstChild("BrokenDreamsLobbyState") and SSS:FindFirstChild("BrokenDreamsLobbyAPI") and SSS:FindFirstChild("BrokenDreamsLobbyServer"),"La integración requiere los adaptadores originales del lobby")
local hud=game:GetService("StarterGui"):FindFirstChild("BrokenDreamsLobbyHUD")
assert(hud and hud:FindFirstChild("LobbyHUD") and hud:FindFirstChild("Panel"),"No se encontró el HUD original")
assert(not SS:FindFirstChild("BrokenDreamsMaps"),"Ya existe BrokenDreamsMaps: conserva esa carpeta e integra manualmente los módulos")
-- Todos los controles previos ocurren antes de escribir.
local backup=Instance.new("Folder");backup.Name="BD_BackupAntesPartidas_"..os.date("!%Y%m%d_%H%M%S");backup.Parent=SS
backup:SetAttribute("BD_IgnoreMapDiscovery",true)
local old=Instance.new("StringValue");old.Name="LobbyHUD_SourceOriginal";old.Value=hud.LobbyHUD.Source;old.Parent=backup
local stateCopy=RS.BrokenDreamsLobbyState:Clone();stateCopy.Parent=backup
local copy=package.BrokenDreams:Clone();copy.Parent=RS
local scripts=package.ServerModules:Clone();scripts.Name="BrokenDreams";scripts.Parent=SSS
local maps=package.BrokenDreamsMaps:Clone();maps.Parent=SS
hud.LobbyHUD.Source=package.HUDSource.Value
RS.BrokenDreamsLobbyState:SetAttribute("LobbyWaitSeconds",30)
RS.BrokenDreamsLobbyState:SetAttribute("RoundPhase","WAITING_FOR_PLAYERS")
for _,o in scripts:GetDescendants() do if o:IsA("Script") then o.Disabled=false end end
-- Guardamos el paquete como respaldo inerte, sin destruirlo.
package.Parent=backup
game:GetService("ChangeHistoryService"):SetWaypoint("BROKEN DREAMS · sistema de partidas instalado")
print("Instalado. Geometría del lobby intacta. Prueba desde Test con 3 clientes. Arena provisional solo Studio.")
