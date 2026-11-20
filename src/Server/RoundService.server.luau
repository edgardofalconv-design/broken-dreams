local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ServerStorage=game:GetService("ServerStorage")
local RunService=game:GetService("RunService")
local root=ReplicatedStorage:WaitForChild("BrokenDreams")
local shared=root:WaitForChild("Shared")
local config=require(shared.GameConfig)
local registry=require(shared.CharacterRegistry)
local mapRegistry=require(shared.MapRegistry)
local runtime=root:WaitForChild("RoundState")
if runtime:GetAttribute("Running") then warn("[BROKEN DREAMS] Controlador duplicado rechazado");return end
runtime:SetAttribute("Running",true)
local remotes=root.Remotes
local lobby=workspace:WaitForChild("BrokenDreamsLobby",10)
local lobbyState=ReplicatedStorage:FindFirstChild("BrokenDreamsLobbyState")
if not lobby or not lobbyState then runtime:SetAttribute("Running",false);warn("[BROKEN DREAMS] Falta el lobby original; no se ha creado uno nuevo");return end
local API=require(game:GetService("ServerScriptService"):WaitForChild("BrokenDreamsLobbyAPI"))
local random=Random.new()
local Core=require(script.Parent.RoundCore)
local core=Core.new(config,registry.Order,function(n)return random:NextInteger(1,n)end)
local hooks=require(script.Parent.IntegrationHooks)
local malicia=require(script.Parent.MaliciaService).new(config,hooks)
local avatar=require(script.Parent.AvatarService).new(config,registry)
local spawn=require(script.Parent.SpawnService).new(config,lobby)
local maps=require(script.Parent.MapService).new(mapRegistry,spawn,config,lobby)
local revive=require(script.Parent.ReviveService).new(core,config,Players)
local escape=require(script.Parent.EscapeService).new(core,Players)
local results=require(script.Parent.ResultsService).new(hooks)
local limiter=require(script.Parent.RateLimiter).new(8,4)
local candidate=nil;local diagnostic="";local retryAt=0
local preparing=false;local returning=false;local controlledLoads={};local recovery={};local outReturned={};local playerConnections={}
local lastState="";local lastRound=0;local publishAt=0;local lastBoard="";local lastWarning=""
local health
local function now() return workspace:GetServerTimeNow() end
local function present(player) return player.Parent==Players end
local function participantList()
 local list={}
 for _,player in Players:GetPlayers() do
  local ok,value=pcall(malicia.Get,malicia,player)
  if ok then
   table.insert(list,{id=player.UserId,name=player.DisplayName,malicia=value})
   player:SetAttribute("BDMalicia",value)
  elseif lastWarning~=tostring(value) then lastWarning=tostring(value);warn("[BROKEN DREAMS] "..lastWarning) end
 end
 return list
end
local function loadAvatar(player,record)
 controlledLoads[player.UserId]=true
 local ok,err=avatar:Load(player,record)
 controlledLoads[player.UserId]=nil
 return ok,err
end
local function resetAttributes(player)
 for _,name in {"BDHealth","BDLives","BDStatus","BDRole","BDCharacter","BDResult"} do player:SetAttribute(name,nil) end
end
local function moveLobby(player,index)
 if not present(player) then return end
 spawn:Teleport(player,spawn:LobbyCFrame(index))
 player.RespawnLocation=lobby.PlayerSpawns.LobbySpawn
end
local function recoverCharacter(player,cf)
 local id=player.UserId;local p=core.roster[id]
 if recovery[id] or not p or not core:IsActive() then return end
 recovery[id]=true
 local round=core.roundId
 -- Reset/muerte ambiental no concede segundos al asesino.
 if p.role=="KILLER" then
  core:Finish(now(),"KILLER_LEFT")
 elseif p.status=="ALIVE" then core:Damage(id,p.health,nil,now()) end
 task.spawn(function()
  health:Unbind(id)
  local ok=loadAvatar(player,p)
  if ok and core.roundId==round and core:IsActive() and (p.status=="ALIVE" or p.status=="DOWNED") then
   local location=cf
   -- Un reset fuera de límites se recupera en un spawn validado del mapa.
   if maps.active then
    local bounds=maps.active.bounds;local v=bounds.CFrame:PointToObjectSpace(cf.Position);local half=bounds.Size/2
    if math.abs(v.X)>half.X or math.abs(v.Z)>half.Z or math.abs(v.Y)>half.Y then location=maps.active.survivors[1].cframe end
   end
   spawn:Teleport(player,location);health:Bind(player)
  else
   if core:IsActive() and p.status=="DOWNED" and not ok then core:Eliminate(id,nil,now()) end
   moveLobby(player)
  end
  recovery[id]=nil
 end)
end
health=require(script.Parent.HealthService).new(core,avatar,recoverCharacter)

local function message(player,text) if present(player) then remotes.Notice:FireClient(player,text) end end
local function selection(player,name)
 if type(name)~="string" or #name>40 or not table.find(registry.Order,name) then return end
 local model
 for _,item in lobby.CharacterGallery:GetChildren() do if item:GetAttribute("CharacterName")==name then model=item;break end end
 local surface=model and model:FindFirstChild("DisplaySurface",true)
 local character=player.Character;local rootPart=character and character:FindFirstChild("HumanoidRootPart")
 if not surface or not rootPart or (surface.Position-rootPart.Position).Magnitude>config.SelectionDistance then message(player,"Acércate al cuadro para elegir");return end
 local ok,text=core:Select(player.UserId,name)
 if ok then player:SetAttribute("BDPreference",name) end
 message(player,text)
end
for _,model in lobby.CharacterGallery:GetChildren() do
 local name=model:GetAttribute("CharacterName");local surface=model:FindFirstChild("DisplaySurface",true)
 if name and surface then
  local prompt=surface:FindFirstChild("BD_SelectCharacter")
  if not prompt then prompt=Instance.new("ProximityPrompt");prompt.Name="BD_SelectCharacter";prompt.Parent=surface end
  prompt.ActionText="Elegir superviviente";prompt.ObjectText=name;prompt.MaxActivationDistance=config.SelectionDistance
  prompt.RequiresLineOfSight=false;prompt.HoldDuration=.25
  prompt.Triggered:Connect(function(player) if limiter:Allow(player.UserId,now()) then selection(player,name) end end)
 end
end
local function snapshot()
 local roster={}
 for id,p in core.roster do
  table.insert(roster,{id=id,name=p.name,role=p.role,character=p.character,status=p.status,health=p.health,lives=p.lives,bleedoutAt=p.bleedoutAt})
 end
 table.sort(roster,function(a,b)return a.id<b.id end)
 return {state=core.state,roundId=core.roundId,deadline=core.deadline,serverNow=now(),roster=roster,
  portalOpen=core.portalOpen,lmsSurvivorId=core.lmsSurvivorId,killerId=core.killerId,
  results=core.results,aggregate=core.aggregate,reason=core.reason,diagnostic=diagnostic,maxHealth=config.MaximumHealth,
  map=candidate and candidate.entry.Name or "MAPA NO DISPONIBLE"}
end
remotes.Request.OnServerEvent:Connect(function(player,action,value)
 if type(action)~="string" or #action>24 or not limiter:Allow(player.UserId,now()) then return end
 local time=now()
 if core:IsActive() and time>=core.deadline then core:Finish(time,"TIMEOUT") end
 if action=="Sync" then remotes.Snapshot:FireClient(player,snapshot())
 elseif action=="Select" then selection(player,value)
 elseif action=="ReviveBegin" and type(value)=="number" and value==value and value%1==0 then revive:Begin(player.UserId,value,time)
 elseif action=="ReviveCancel" then revive:Cancel(player.UserId) end
end)

local function updateBoards(players)
 local bestValue=-math.huge;local leaders={}
 for _,p in players do
  if p.malicia>bestValue then bestValue=p.malicia;leaders={p}
  elseif p.malicia==bestValue then table.insert(leaders,p) end
 end
 local record=core.killerId and core.roster[core.killerId]
 local picked=record and core.state~="WAITING_FOR_PLAYERS" and core.state~="INTERMISSION"
 local name=picked and record.name or (#leaders==1 and leaders[1].name or #leaders>1 and "EMPATE · "..#leaders.." JUGADORES" or "POR DETERMINAR")
 local id=picked and record.id or (#leaders==1 and leaders[1].id or 0)
 local score=0
 for _,p in players do if p.id==id then score=p.malicia end end
 if not picked and #leaders>1 then score=bestValue end
 local text=name.." · MALICIA "..tostring(score)
 if text~=lastBoard then
  lastBoard=text;lobbyState:SetAttribute("MaliciaValue",score);lobbyState:SetAttribute("MaliciaUserId",id);lobbyState:SetAttribute("MaliciaName",text)
 end
 API.SetCountdown(core:Remaining(now()))
 lobbyState:SetAttribute("RoundPhase",core.state)
 for _,model in lobby.CharacterGallery:GetChildren() do
  local display=model:FindFirstChild("DisplaySurface",true);display=display and display:FindFirstChild("Display")
  local name=model:GetAttribute("CharacterName")
  if display and name then
   local owner=nil
   for _,p in core.roster do if p.role=="SURVIVOR" and p.character==name then owner=p.name end end
   display.Detail.Text=owner and ("RESERVADO · "..owner) or "ELIGE EN EL CUADRO"
  end
 end
end

local function equipTestTool(player)
 if not RunService:IsStudio() or not config.StudioToolsEnabled then return end
 local backpack=player:FindFirstChildOfClass("Backpack");if not backpack then return end
 local tool=Instance.new("Tool");tool.Name="STUDIO · Daño de prueba";tool.RequiresHandle=false;tool.CanBeDropped=false
 local round=core.roundId;local nextHit=0
 tool.Activated:Connect(function()
  if not RunService:IsStudio() or core.roundId~=round or core.killerId~=player.UserId or not core:IsActive() or now()<nextHit then return end
  nextHit=now()+.8
  local actor=player.Character and player.Character:FindFirstChild("HumanoidRootPart");if not actor then return end
  local nearest,dist=nil,12
  for id,p in core.roster do
   local target=Players:GetPlayerByUserId(id);local targetRoot=target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
   if p.role=="SURVIVOR" and p.status=="ALIVE" and targetRoot then
    local delta=targetRoot.Position-actor.Position
    local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={player.Character,target.Character};ray.RespectCanCollide=true
    if delta.Magnitude<dist and not workspace:Raycast(actor.Position,delta,ray) then nearest=target;dist=delta.Magnitude end
   end
  end
  if nearest then health:Damage(nearest,config.StudioDamage,player) end
 end)
 tool.Parent=backpack
end
local function removeTestTools(player)
 for _,container in {player:FindFirstChildOfClass("Backpack"),player.Character} do
  if container then for _,item in container:GetChildren() do if item:IsA("Tool") and item.Name=="STUDIO · Daño de prueba" then item:Destroy() end end end
 end
end

local function prepareRound()
 if preparing then return end;preparing=true
 local round=core.roundId
 task.spawn(function()
  local ok,err=xpcall(function()
   local active,problem=maps:Prepare(candidate)
   if not active then error(problem) end
   local survivors={};for _,p in core.roster do if p.role=="SURVIVOR" then table.insert(survivors,p) end end
   table.sort(survivors,function(a,b)return a.id<b.id end)
   local positions={[core.killerId]=active.killer.cframe}
   for i,p in survivors do positions[p.id]=active.survivors[i].cframe end
   local pending=0;local failure=nil
   for id,p in core.roster do
    local player=Players:GetPlayerByUserId(id)
    if player then
     avatar:Save(player);pending+=1
     task.spawn(function()
      local success,why=loadAvatar(player,p)
      if success and core.roundId==round and core.state=="PREPARING_ROUND" and core.roster[id]==p and present(player) then
       success,why=spawn:Teleport(player,positions[id])
       if success then health:Bind(player) end
      else success=false;why=why or "Preparación cancelada" end
      if not success then failure=why end
      pending-=1
     end)
    end
   end
   local untilTime=os.clock()+config.CharacterLoadTimeout+2
   repeat task.wait(.05) until pending==0 or os.clock()>=untilTime or core.state~="PREPARING_ROUND"
   if core.roundId~=round or core.state~="PREPARING_ROUND" then return end
   if pending>0 or failure then error(failure or "Tiempo agotado preparando participantes") end
   if core:StartRound(now()) then
    for id,p in core.roster do
     local player=Players:GetPlayerByUserId(id)
     if player then
      player:SetAttribute("BDRole",p.role);player:SetAttribute("BDCharacter",p.character);health:Sync(player)
      if p.role=="KILLER" then equipTestTool(player) end
     end
    end
   end
  end,function(e)return tostring(e).."\n"..debug.traceback()end)
  if not ok then
   warn("[BROKEN DREAMS] Preparación cancelada: "..tostring(err))
   diagnostic=tostring(err):match("^[^\n]+") or "Error preparando mapa"
   if core.roundId==round and core.state=="PREPARING_ROUND" then core:Abort(now(),"No se pudo preparar el mapa o los avatares") end
  end
  preparing=false
 end)
end
local function returnRound()
 if returning then return end;returning=true
 task.spawn(function()
  revive:Cleanup();escape:Cleanup();health:Cleanup()
  local ok,err=xpcall(function()
   local pending=0
   for index,player in Players:GetPlayers() do
    removeTestTools(player)
    if avatar.saved[player.UserId] then
     pending+=1
     task.spawn(function()
      controlledLoads[player.UserId]=true
      local restored=avatar:Restore(player)
      if not restored then loadAvatar(player,nil) end
      controlledLoads[player.UserId]=nil
      resetAttributes(player);moveLobby(player,index);pending-=1
     end)
    else resetAttributes(player);moveLobby(player,index) end
   end
   local stop=os.clock()+config.CharacterLoadTimeout+3
   repeat task.wait(.05) until pending==0 or os.clock()>=stop
  end,function(e)return tostring(e).."\n"..debug.traceback()end)
  if not ok then warn("[BROKEN DREAMS] Recuperación del lobby: "..err) end
  maps:Cleanup();outReturned={};candidate=nil;retryAt=now()+config.MapRetrySeconds
  core:Returned(now());returning=false
 end)
end

local function joined(player)
 player.RespawnLocation=lobby.PlayerSpawns.LobbySpawn
 local function characterAdded(character)
  local expected=controlledLoads[player.UserId]==true
  task.spawn(function()
   local rootPart=character:WaitForChild("HumanoidRootPart",10)
   if not rootPart or player.Character~=character or not present(player) or expected then return end
   local p=core.roster[player.UserId]
   if core:IsActive() and p and (p.status=="ALIVE" or p.status=="DOWNED") then
    recoverCharacter(player,rootPart.CFrame)
   else moveLobby(player) end
  end)
 end
 playerConnections[player.UserId]=player.CharacterAdded:Connect(characterAdded)
 if player.Character then characterAdded(player.Character) end
end
Players.PlayerAdded:Connect(joined)
Players.PlayerRemoving:Connect(function(player)
 core:Disconnect(player.UserId,now());health:Unbind(player.UserId);revive:Cancel(player.UserId)
 malicia:Forget(player);limiter:Forget(player.UserId)
 local connection=playerConnections[player.UserId];if connection then connection:Disconnect();playerConnections[player.UserId]=nil end
 avatar:Forget(player.UserId)
end)
for _,player in Players:GetPlayers() do joined(player) end

-- Única puerta de pruebas, solo servidor y creada exclusivamente dentro de Studio.
if RunService:IsStudio() and config.StudioToolsEnabled then
 local debugFunction=Instance.new("BindableFunction");debugFunction.Name="BrokenDreamsDebug";debugFunction.Parent=ServerStorage
 debugFunction.OnInvoke=function(command,userId,value)
  assert(RunService:IsStudio(),"Solo Studio")
  local player=type(userId)=="number" and Players:GetPlayerByUserId(userId) or nil
  if command=="Status" then return snapshot()
  elseif command=="Intermission" then assert(type(value)=="number" and value>=0 and value<=300);core.intermissionOverride=value;return true
  elseif command=="Start" then
   if #participantList()<config.MinimumPlayers or not candidate then return false,"Faltan jugadores o mapa válido" end
   if core.state=="WAITING_FOR_PLAYERS" then core:Step(now(),participantList(),true) end
   if core.state=="INTERMISSION" then core.deadline=now();return true end
   return false,"La ronda ya está en curso"
  elseif command=="Malicia" then assert(player,"Jugador no encontrado");malicia:SetStudio(player,value);return true
  elseif command=="Killer" then
   assert(player,"Jugador no encontrado");assert(core.state=="WAITING_FOR_PLAYERS" or core.state=="INTERMISSION","Configura antes de seleccionar")
   local maximum=0;for _,p in participantList() do maximum=math.max(maximum,p.malicia) end
   malicia:SetStudio(player,maximum+1);return true -- mantiene la regla de mayor Malicia
  elseif command=="Damage" or command=="Down" then
   assert(player,"Jugador no encontrado");return health:Damage(player,command=="Down" and config.MaximumHealth or value,Players:GetPlayerByUserId(core.killerId or 0))
  elseif command=="Revive" then assert(player,"Jugador no encontrado");return core:Revive(player.UserId,now())
  elseif command=="Escape" then if core:IsActive() then core.portalOpen=true;return true end;return false
  elseif command=="LMS" then return core:BeginLMS(now(),true)
  elseif command=="End" then return core:Finish(now(),"STUDIO_END")
  elseif command=="Time" then assert(core:IsActive() and type(value)=="number" and value>=0 and value<=600);core.deadline=now()+value;return true
  end
  return false,"Comando desconocido"
 end
end

local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.1 then return end;elapsed=0
 if core.state=="WAITING_FOR_PLAYERS" and #Players:GetPlayers()==0 then return end
 local ok,err=xpcall(function()
  local time=now();local players=participantList()
  if core.state=="WAITING_FOR_PLAYERS" and time>=retryAt and not preparing and not returning then
   candidate,diagnostic=maps:Next();diagnostic=diagnostic or "";retryAt=time+config.MapRetrySeconds
   API.SetNextMap(candidate and candidate.entry.Name or "MAPA NO DISPONIBLE",candidate and candidate.entry.Image or "")
  end
  core:Step(time,players,candidate~=nil)
  if core.state=="PREPARING_ROUND" then prepareRound()
  elseif core:IsActive() then
   revive:Step(time)
   if core.portalOpen and maps.active then escape:Open(maps.active.escape) end
   escape:Step(time)
   for id,p in core.roster do
    local player=Players:GetPlayerByUserId(id)
    if player then
     health:Sync(player)
     if (p.status=="ESCAPED" or p.status=="ELIMINATED") and not outReturned[id] then
      outReturned[id]=true;moveLobby(player)
     end
    end
   end
  elseif core.state=="ROUND_RESULTS" then
   results:Deliver(core,Players);revive:Cleanup()
  elseif core.state=="RETURN_TO_LOBBY" then returnRound() end
  if core.state~=lastState or core.roundId~=lastRound then
   lastState=core.state;lastRound=core.roundId;publishAt=0
   if core.state=="ROUND_RESULTS" then
    for _,player in Players:GetPlayers() do removeTestTools(player);health:Sync(player) end
   end
  end
  if time>=publishAt then
   publishAt=time+.25;updateBoards(players)
   runtime:SetAttribute("Phase",core.state);runtime:SetAttribute("Deadline",core.deadline)
   runtime:SetAttribute("RoundId",core.roundId);runtime:SetAttribute("Diagnostic",diagnostic)
   remotes.Snapshot:FireAllClients(snapshot())
  end
 end,function(e)return tostring(e).."\n"..debug.traceback()end)
 if not ok then
  if lastWarning~=err then lastWarning=err;warn("[BROKEN DREAMS] "..err) end
  if core:IsActive() or core.state=="PREPARING_ROUND" or core.state=="CHARACTER_SELECTION" then core:Abort(now(),"Error recuperable del servidor") end
 end
end)
