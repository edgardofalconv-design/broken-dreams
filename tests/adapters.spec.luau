-- Pruebas locales con dobles explícitos. No simulan el motor de Roblox ni su red.
local rb=require("@lune/roblox")
local Core=require("../src/Server/RoundCore")
local Config=require("../src/Shared/GameConfig")
local Registry=require("../src/Shared/CharacterRegistry")
local Revive=require("../src/Server/ReviveService")
local Spawn=require("../src/Server/SpawnService")
local Results=require("../src/Server/ResultsService")
local passed=0
local function test(name,fn)local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed+=1;print("PASS "..name)end
local Vector3,CFrame=rb.Vector3,rb.CFrame
local roster={};local roots={};local blocked=false
local players={GetPlayerByUserId=function(_,id)return roster[id] end,GetPlayers=function()return {}end}
for i=1,4 do
 roots[i]={Position=Vector3.new(i*2,0,0)}
 roster[i]={UserId=i,DisplayName="Player"..i,Character={FindFirstChild=function()return roots[i]end},SetAttribute=function()end}
end
local function environment(fn,extra)
 local old=getfenv(fn);local env=setmetatable(extra,{__index=old});setfenv(fn,env)
end
environment(Revive.Valid,{RaycastParams={new=function()return {}end},Enum=rb.Enum,workspace={Raycast=function()return blocked and {} or nil end}})
local function active()
 local config=table.clone(Config);config.LobbyCountdownOnly=false
 local c=Core.new(config,Registry.Order,function()return 1 end)
 local ps={};for i=1,4 do table.insert(ps,{id=i,name="Player"..i,malicia=i}) end
 c:Step(0,ps,true);c:Step(30,ps,true);c:Step(45,ps,true);c:StartRound(45)
 return c
end
test("Reanimación rechaza uno mismo, asesino, distancia y pared",function()
 local c=active();c:Damage(2,100,4,50);local r=Revive.new(c,Config,players)
 assert(not r:Valid(2,2));assert(not r:Valid(4,2));assert(r:Valid(1,2))
 roots[1].Position=Vector3.new(100,0,0);assert(not r:Valid(1,2));roots[1].Position=Vector3.new(2,0,0)
 blocked=true;assert(not r:Valid(1,2));blocked=false
end)
local function reviveSetup()
 local c=active();c:Damage(2,100,4,50);local r=Revive.new(c,Config,players)
 r.prompts[2]={Parent=roots[2],Destroy=function()end};return c,r
end
test("Duración de reanimación medida por servidor",function()
 local c,r=reviveSetup();assert(r:Begin(1,2,51));r:Step(54.99);assert(c.roster[2].status=="DOWNED")
 r:Step(55);assert(c.roster[2].status=="ALIVE" and c.roster[2].lives==1)
end)
test("Soltar o alejarse interrumpe reanimación",function()
 local c,r=reviveSetup();r:Begin(1,2,51);r:Cancel(1);r:Step(56);assert(c.roster[2].status=="DOWNED")
 r:Begin(1,2,57);roots[1].Position=Vector3.new(100,0,0);r:Step(62);assert(c.roster[2].status=="DOWNED" and not r.sessions[1]);roots[1].Position=Vector3.new(2,0,0)
end)
test("Perder estado vivo interrumpe reanimación",function()
 local c,r=reviveSetup();r:Begin(1,2,51);c:Damage(1,100,4,52)
 r.prompts[1]={Parent=roots[1],Destroy=function()end};r:Step(56);assert(c.roster[2].status=="DOWNED" and not r.sessions[1])
end)
test("Resultados se entregan una vez por usuario y ronda",function()
 local calls=0;local p={GetPlayerByUserId=function(_,id)return roster[id]end}
 environment(Results.Deliver,{game={JobId="test-local"},task={spawn=function(fn)fn()end}})
 local r=Results.new({OnResult=function()calls+=1 end});local c=active();c:Finish(50,"STUDIO_END")
 r:Deliver(c,p);r:Deliver(c,p);assert(calls==4)
 c.roundId+=1;r:Deliver(c,p);assert(calls==8)
end)
test("Acciones tardías no extienden una ronda ya vencida",function()
 local c=active();c:Damage(1,100,4,50);c:Revive(1,54)
 assert(not c:Damage(1,100,4,400));assert(c.state=="ROUND_RESULTS" and c.reason=="TIMEOUT")
 c=active();c.portalOpen=true;assert(not c:Escape(1,400));assert(c.reason=="TIMEOUT")
 c=active();assert(not c:BeginLMS(400,true));assert(c.reason=="TIMEOUT")
end)
-- Raycasts y overlap son dobles: se prueba rechazo/aceptación de resultados del motor,
-- no se atribuyen estas comprobaciones a una sesión real de Studio.
local ground={IsDescendantOf=function(_,map)return map~=nil end}
local map={RoundSpawns={}}
local marker={Anchored=true,CanCollide=false,Position=Vector3.new(400,8.5,0),CFrame=CFrame.new(400,8.5,0),IsA=function(_,name)return name=="BasePart"end}
local bounds={CFrame=CFrame.new(400,18.4,0),Size=Vector3.new(114,30,104)}
local rayMode="safe";local overlap=false
local fakeWorld={
 Raycast=function(_,origin,_direction)
  if rayMode=="missing" then return nil end
  return {Instance=ground,Position=Vector3.new(origin.X,8.4,origin.Z),Normal=rayMode=="slope" and Vector3.new(1,0,0) or Vector3.new(0,1,0)}
 end,
 GetPartBoundsInBox=function()return overlap and {{CanCollide=true,Name="Obstacle"}} or {}end,
}
local state={GetAttribute=function(_,key)
 return ({Origin=Vector3.new(0,8,0),LobbyBoundsMin=Vector3.new(-94,-8,-88),LobbyBoundsMax=Vector3.new(94,60,88)})[key]
end}
environment(Spawn.Validate,{workspace=fakeWorld,Vector3=Vector3,CFrame=CFrame,Enum=rb.Enum,RaycastParams={new=function()return {}end},OverlapParams={new=function()return {}end},game={GetService=function(_,name)
 if name=="Players" then return players end
 return {FindFirstChild=function()return state end}
end}})
test("Spawn seguro requiere suelo, pendiente y volumen libres",function()
 local s=Spawn.new(Config,{})
 assert(s:Validate(map,marker,bounds));rayMode="missing";assert(not s:Validate(map,marker,bounds))
 rayMode="slope";assert(not s:Validate(map,marker,bounds));rayMode="safe"
 overlap=true;assert(not s:Validate(map,marker,bounds));overlap=false
end)
test("Spawn fuera de PlayBounds rechazado",function()
 local s=Spawn.new(Config,{});marker.Position=Vector3.new(900,8.5,0);assert(not s:Validate(map,marker,bounds));marker.Position=Vector3.new(400,8.5,0)
end)
test("Spawn dentro del lobby rechazado",function()
 local s=Spawn.new(Config,{});marker.Position=Vector3.new(0,8.5,0);local localBounds={CFrame=CFrame.new(0,18,0),Size=Vector3.new(114,30,104)}
 assert(not s:Validate(map,marker,localBounds));marker.Position=Vector3.new(400,8.5,0)
end)
print("TOTAL "..passed.." pruebas de adaptadores con dobles locales pasadas; NO motor Roblox")
