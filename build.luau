-- Ejecutar desde la raíz del workspace con Lune 0.11.1. No requiere ni simula Studio.
local fs=require("@lune/fs")
local serde=require("@lune/serde")
local rb=require("@lune/roblox")
local Instance,Vector3,CFrame,Color3,Enum,Vector2,UDim2=rb.Instance,rb.Vector3,rb.CFrame,rb.Color3,rb.Enum,rb.Vector2,rb.UDim2
local path="work/rounds/"
local game=rb.deserializePlace(fs.readFile(path.."backups/Broken-Dreams-Antes-Partidas.rbxlx"))
local lobby=game:GetService("Workspace").BrokenDreamsLobby
local original={};local originalScripts={};local inventory={}
for _,o in game:GetDescendants() do
 if o:IsA("BasePart") then table.insert(original,{o,o.CFrame,o.Size,o.Color,o.Material,o.CanCollide,o.Transparency}) end
 if o:IsA("LuaSourceContainer") then originalScripts[o:GetFullName()]=o.Source end
 if o.Parent==game or o.Parent==lobby then table.insert(inventory,{path=o:GetFullName(),class=o.ClassName}) end
end
assert(#original==5580)
local function new(class,name,parent)
 local o=Instance.new(class);o.Name=name;o.Parent=parent;return o
end
local replicated=game:GetService("ReplicatedStorage")
assert(not replicated:FindFirstChild("BrokenDreams"),"No sobrescribir un sistema existente")
local root=new("Folder","BrokenDreams",replicated)
root:SetAttribute("SystemVersion","0.2.0-rounds-preview")
local shared=new("Folder","Shared",root)
local client=new("Folder","Client",root)
local remotes=new("Folder","Remotes",root)
for _,name in {"Request","Snapshot","Notice"} do new("RemoteEvent",name,remotes) end
local state=new("Folder","RoundState",root);state:SetAttribute("Phase","WAITING_FOR_PLAYERS");state:SetAttribute("Deadline",0)
local server=new("Folder","BrokenDreams",game:GetService("ServerScriptService"))
local function scripts(folder,dir)
 for _,file in fs.readDir(path.."src/"..dir) do
  if file:match("%.luau$") and file~="LobbyHUD.client.luau" then
   local isScript=file:match("%.server%.luau$")
   local name=file:gsub("%.server%.luau$",""):gsub("%.luau$","")
   local o=new(isScript and "Script" or "ModuleScript",name,folder)
   o.Source=fs.readFile(path.."src/"..dir.."/"..file)
  end
 end
end
scripts(shared,"Shared");scripts(client,"Client");scripts(server,"Server")
local hud=game:GetService("StarterGui").BrokenDreamsLobbyHUD
local oldHUD=hud.LobbyHUD.Source
hud.LobbyHUD.Source=fs.readFile(path.."src/Client/LobbyHUD.client.luau")
local lobbyState=replicated.BrokenDreamsLobbyState
lobbyState:SetAttribute("LobbyWaitSeconds",30)
lobbyState:SetAttribute("RoundPhase","WAITING_FOR_PLAYERS")

-- Arena provisional autorizada, independiente y guardada fuera de Workspace.
-- No tiene el nombre ni pretende ser The Forgotten Glade.
local mapFolder=new("Folder","BrokenDreamsMaps",game:GetService("ServerStorage"))
local arena=new("Model","BD_TestArena",mapFolder)
arena:SetAttribute("BDMapId","round_test");arena:SetAttribute("Provisional",true);arena:SetAttribute("StudioOnly",true)
local geometry=new("Model","Geometry",arena)
local function part(name,size,position,color,material,parent,collide)
 local o=new("Part",name,parent or geometry);o.Size=size;o.CFrame=CFrame.new(position)
 o.Color=color;o.Material=material or Enum.Material.SmoothPlastic;o.Anchored=true
 o.CanCollide=collide~=false;o.CanQuery=collide~=false;o.CanTouch=false
 o.TopSurface=Enum.SurfaceType.Smooth;o.BottomSurface=Enum.SurfaceType.Smooth;return o
end
local stone=Color3.fromRGB(61,57,76);local gold=Color3.fromRGB(151,116,63)
part("TestGround",Vector3.new(120,2,110),Vector3.new(400,7.4,0),Color3.fromRGB(66,70,67),Enum.Material.Slate)
for _,x in {340,460} do part("BoundaryWall",Vector3.new(3,12,113),Vector3.new(x,14.4,0),stone,Enum.Material.Slate) end
for _,z in {-55,55} do part("BoundaryWall",Vector3.new(120,12,3),Vector3.new(400,14.4,z),stone,Enum.Material.Slate) end
for _,x in {376,424} do for _,z in {-14,14} do
 part("TestCover",Vector3.new(7,6,12),Vector3.new(x,11.4,z),stone,Enum.Material.Rock)
 part("CoverTrim",Vector3.new(7.2,.25,12.2),Vector3.new(x,14.55,z),gold,Enum.Material.SmoothPlastic,nil,false)
end end
for _,x in {345,455} do for _,z in {-47,0,47} do
 part("TestColumn",Vector3.new(3,13,3),Vector3.new(x,14.9,z),stone,Enum.Material.Basalt)
 local glow=part("SoftGlow",Vector3.new(3.2,.4,3.2),Vector3.new(x,21.5,z),Color3.fromRGB(135,77,178),Enum.Material.Neon,nil,false)
 local light=new("PointLight","TestLight",glow);light.Range=24;light.Brightness=.65;light.Color=glow.Color;light.Shadows=false
end end
for _,z in {-27,27} do part("TestLane",Vector3.new(102,.04,1),Vector3.new(400,8.43,z),gold,Enum.Material.SmoothPlastic,nil,false) end
local sign=part("ProvisionalNotice",Vector3.new(40,6,.3),Vector3.new(400,16,-53.3),stone,Enum.Material.SmoothPlastic,nil,false)
local surface=new("SurfaceGui","Notice",sign);surface.Face=Enum.NormalId.Back;surface.CanvasSize=Vector2.new(1400,210)
local label=new("TextLabel","Text",surface);label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBold;label.TextScaled=true
label.TextColor3=Color3.fromRGB(237,204,150);label.Text="BROKEN DREAMS · ARENA PROVISIONAL\nNO ES THE FORGOTTEN GLADE"
local bounds=part("PlayBounds",Vector3.new(114,30,104),Vector3.new(400,18.4,0),stone,nil,arena,false);bounds.Transparency=1
local spawns=new("Folder","RoundSpawns",arena)
local function marker(name,pos,parent)
 local o=part(name,Vector3.new(1,.2,1),pos,Color3.fromRGB(230,180,255),nil,parent,false);o.Transparency=1;return o
end
marker("Killer",Vector3.new(400,8.5,-34),spawns).CFrame=CFrame.new(400,8.5,-34)*CFrame.Angles(0,math.pi,0)
marker("Escape",Vector3.new(445,8.5,0),spawns)
local survivors=new("Folder","Survivors",spawns)
for i=1,6 do marker(string.format("Survivor%02d",i),Vector3.new(365+i*10,8.5,34),survivors) end

for _,entry in original do
 local o=entry[1]
 assert(o.Parent and o.CFrame==entry[2] and o.Size==entry[3] and o.Color==entry[4] and o.Material==entry[5] and o.CanCollide==entry[6] and o.Transparency==entry[7],"Contenido original alterado")
end
for name,source in originalScripts do
 if not name:match("LobbyHUD$") then
  local found=false
  for _,o in game:GetDescendants() do if o:IsA("LuaSourceContainer") and o:GetFullName()==name then assert(o.Source==source);found=true end end
  assert(found,"Script original perdido: "..name)
 end
end
local output=path.."Broken-Dreams-Partidas.rbxlx"
fs.writeFile(output,rb.serializePlace(game,true))
local check=rb.deserializePlace(fs.readFile(output))
assert(check:GetService("Workspace").BrokenDreamsLobby.ForestExterior)
assert(check:GetService("ServerStorage").BrokenDreamsMaps.BD_TestArena)
assert(check:GetService("StarterGui").BrokenDreamsLobbyHUD.LobbyHUD.Source==hud.LobbyHUD.Source)
-- Paquete importable para un proyecto local más reciente. Scripts inertes hasta instalar.
local package=new("Model","BrokenDreamsRoundPackage",nil)
package:SetAttribute("BD_IgnoreMapDiscovery",true)
root:Clone().Parent=package
local serverCopy=server:Clone();serverCopy.Name="ServerModules";serverCopy.Parent=package
for _,o in serverCopy:GetDescendants() do if o:IsA("Script") then o.Disabled=true end end
local source=new("StringValue","HUDSource",package);source.Value=hud.LobbyHUD.Source
mapFolder:Clone().Parent=package
fs.writeFile(path.."Broken-Dreams-Sistema-Partidas.rbxmx",rb.serializeModel({package},true))
fs.writeFile(path.."backups/LobbyHUD-original.client.luau",oldHUD)
fs.writeFile(path.."INSPECCION.json",serde.encode("json",{
 baseCommit="0bac0d0079bb7dd3c896c6313e470c42d3ac7bdb",originalPartsPreserved=#original,
 originalScripts=originalScripts,topLevelInventory=inventory,officialMapExists=false,
 provisionalMap="ServerStorage.BrokenDreamsMaps.BD_TestArena",studioTested=false,
 modifiedExistingScripts={"StarterGui.BrokenDreamsLobbyHUD.LobbyHUD"},
 modifiedAttributes={"BrokenDreamsLobbyState.LobbyWaitSeconds","BrokenDreamsLobbyState.RoundPhase"},
},true))
print("PASS: 5580 piezas originales intactas; .rbxlx releído; arena provisional separada; paquete importable exportado")
