local fs=require("@lune/fs")
local rb=require("@lune/roblox")
local game=rb.deserializePlace(fs.readFile("work/countdown/backups/Antes-Contador.rbxlx"))
local function attributesByPath(root)
 local result={}
 local function visit(parent,path)
  local counts={}
  for _,child in parent:GetChildren() do
   local key=child.ClassName..":"..child.Name;counts[key]=(counts[key] or 0)+1
   local nextPath=path.."/"..key.."["..counts[key].."]"
   result[nextPath]=child:GetAttributes();visit(child,nextPath)
  end
 end
 visit(root,"");return result
end
local originalAttributes=attributesByPath(game)
local root=game:GetService("ReplicatedStorage").BrokenDreams
local server=game:GetService("ServerScriptService").BrokenDreams
local changes={
 {root.Shared.GameConfig,"Shared/GameConfig.luau"},
 {root.Shared.RoundStates,"Shared/RoundStates.luau"},
 {server.RoundCore,"Server/RoundCore.luau"},
 {server.RoundService,"Server/RoundService.server.luau"},
 {root.Client.RoundUIController,"Client/RoundUIController.luau"},
}
for _,change in changes do change[1].Source=fs.readFile("work/countdown/src/"..change[2]) end
assert(not root.Shared:FindFirstChild("TimerFormat"))
local formatter=rb.Instance.new("ModuleScript");formatter.Name="TimerFormat"
formatter.Source=fs.readFile("work/countdown/src/Shared/TimerFormat.luau");formatter.Parent=root.Shared
fs.writeFile("work/countdown/Broken-Dreams-Contador.rbxlx",rb.serializePlace(game,true))
local check=rb.deserializePlace(fs.readFile("work/countdown/Broken-Dreams-Contador.rbxlx"))
local savedAttributes=attributesByPath(check)
for path,attrs in originalAttributes do
 assert(savedAttributes[path],"Instancia original ausente")
 for key,value in attrs do assert(savedAttributes[path][key]==value,"Atributo original modificado: "..path.."."..key) end
 for key in savedAttributes[path] do assert(attrs[key]~=nil,"Atributo nuevo no solicitado") end
end
assert(check:GetService("ReplicatedStorage").BrokenDreams.Shared.TimerFormat.Source==formatter.Source)
print("Proyecto existente actualizado y releído; solo cinco fuentes cambiadas y un módulo nuevo")
