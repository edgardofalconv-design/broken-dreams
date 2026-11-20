-- Ejecutar solo en edición sobre la entrega de partidas anterior. Guarda una copia primero.
assert(not game:GetService("RunService"):IsRunning(),"Detén Play antes de aplicar")
local rs=game:GetService("ReplicatedStorage")
local sss=game:GetService("ServerScriptService")
assert(rs:FindFirstChild("BrokenDreams") and sss:FindFirstChild("BrokenDreams"),"Falta el sistema de partidas anterior")
assert(not rs.BrokenDreams.Shared:FindFirstChild("TimerFormat"),"El ajuste ya existe; no sobrescribir")
local changes={
{target=rs.BrokenDreams.Shared.GameConfig,old=[====[-- Todos los tiempos son segundos. Solo el servidor decide los valores efectivos.
return {
 MinimumPlayers = 2,
 MaximumSurvivors = 6,
 IntermissionSeconds = 30, -- Provisional
 SelectionSeconds = 15, -- Provisional
 RoundSeconds = 355,
 EliminationBonusSeconds = 10,
 LMSSeconds = 217,
 EscapeAtSeconds = 80,
 ResultsSeconds = 8, -- Provisional
 MaximumHealth = 100,
 ReviveHealth = 50, -- Provisional
 ReviveSeconds = 4, -- Provisional
 ReviveDistance = 9,
 BleedoutSeconds = 45, -- Provisional; false desactiva el sangrado
 TimeoutOutcome = "DEFEAT", -- Alternativa de prueba: DRAW
 KillerDisconnectOutcome = "SURVIVOR_WIN", -- Política provisional, sin fingir escapes
 InitialMalicia = 0, -- Temporal, por sesión. No se inventa una economía ni persistencia.
 MapRetrySeconds = 5,
 SelectionDistance = 16,
 SpawnGroundRayHeight = 5,
 SpawnGroundRayDepth = 20,
 SpawnClearance = {4, 6, 4},
 MinimumKillerSpawnSeparation = 24,
 CharacterLoadTimeout = 12,
 StudioToolsEnabled = true, -- Además requiere RunService:IsStudio() en el servidor.
 StudioDamage = 100,
 NormalMusicId = "", -- rbxassetid://ID real autorizado; vacío = silencio
}
]====],new=[====[-- Todos los tiempos son segundos. Solo el servidor decide los valores efectivos.
return {
 LobbyCountdownOnly = true, -- Señal interna al llegar a cero; sin cargar ni teletransportar a mapas.
 MinimumPlayers = 2,
 MaximumSurvivors = 6,
 IntermissionSeconds = 30, -- Provisional
 SelectionSeconds = 15, -- Provisional
 RoundSeconds = 355,
 EliminationBonusSeconds = 10,
 LMSSeconds = 217,
 EscapeAtSeconds = 80,
 ResultsSeconds = 8, -- Provisional
 MaximumHealth = 100,
 ReviveHealth = 50, -- Provisional
 ReviveSeconds = 4, -- Provisional
 ReviveDistance = 9,
 BleedoutSeconds = 45, -- Provisional; false desactiva el sangrado
 TimeoutOutcome = "DEFEAT", -- Alternativa de prueba: DRAW
 KillerDisconnectOutcome = "SURVIVOR_WIN", -- Política provisional, sin fingir escapes
 InitialMalicia = 0, -- Temporal, por sesión. No se inventa una economía ni persistencia.
 MapRetrySeconds = 5,
 SelectionDistance = 16,
 SpawnGroundRayHeight = 5,
 SpawnGroundRayDepth = 20,
 SpawnClearance = {4, 6, 4},
 MinimumKillerSpawnSeparation = 24,
 CharacterLoadTimeout = 12,
 StudioToolsEnabled = true, -- Además requiere RunService:IsStudio() en el servidor.
 StudioDamage = 100,
 NormalMusicId = "", -- rbxassetid://ID real autorizado; vacío = silencio
}
]====]},
{target=rs.BrokenDreams.Shared.RoundStates,old=[====[return {
 WAITING_FOR_PLAYERS="WAITING_FOR_PLAYERS", INTERMISSION="INTERMISSION",
 CHARACTER_SELECTION="CHARACTER_SELECTION", PREPARING_ROUND="PREPARING_ROUND",
 ACTIVE_ROUND="ACTIVE_ROUND", LAST_SURVIVOR_STANDING="LAST_SURVIVOR_STANDING",
 ROUND_RESULTS="ROUND_RESULTS", RETURN_TO_LOBBY="RETURN_TO_LOBBY",
}
]====],new=[====[return {
 ROUND_START_REQUESTED="ROUND_START_REQUESTED",
 WAITING_FOR_PLAYERS="WAITING_FOR_PLAYERS", INTERMISSION="INTERMISSION",
 CHARACTER_SELECTION="CHARACTER_SELECTION", PREPARING_ROUND="PREPARING_ROUND",
 ACTIVE_ROUND="ACTIVE_ROUND", LAST_SURVIVOR_STANDING="LAST_SURVIVOR_STANDING",
 ROUND_RESULTS="ROUND_RESULTS", RETURN_TO_LOBBY="RETURN_TO_LOBBY",
}
]====]},
{target=rs.BrokenDreams.Client.RoundUIController,old=[====[local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local Controller={};Controller.__index=Controller
local phaseNames={
 WAITING_FOR_PLAYERS="ESPERANDO JUGADORES",INTERMISSION="LA PARTIDA COMIENZA EN",
 CHARACTER_SELECTION="ELIGE TU SUPERVIVIENTE",PREPARING_ROUND="PREPARANDO LA PARTIDA",
 ACTIVE_ROUND="SOBREVIVE Y BUSCA LA SALIDA",LAST_SURVIVOR_STANDING="ÚLTIMO SUPERVIVIENTE",
 ROUND_RESULTS="RESULTADOS",RETURN_TO_LOBBY="REGRESANDO AL LOBBY",
}
local resultNames={ESCAPED="ESCAPASTE",SURVIVOR_WIN="VICTORIA DE SUPERVIVIENTES",KILLER_WIN="VICTORIA DEL ASESINO",
 MIXED="RESULTADO MIXTO",DEFEAT="DERROTA",DRAW="EMPATE",CANCELLED="RONDA CANCELADA",KILLER_LEFT="EL ASESINO ABANDONÓ"}
local statusNames={ALIVE="Con vida",DOWNED="Incapacitado",ELIMINATED="Eliminado",ESCAPED="Escapaste",DISCONNECTED="Desconectado"}
local function panel(parent,name,size,position,anchor)
 local p=parent:FindFirstChild(name)
 if p then return p end
 p=Instance.new("Frame");p.Name=name;p.Size=size;p.Position=position;p.AnchorPoint=anchor;p.BackgroundColor3=Color3.fromRGB(27,17,39);p.BackgroundTransparency=.12;p.Parent=parent
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=p
 local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(175,133,67);s.Transparency=.25;s.Parent=p
 return p
end
local function text(parent,name,size,position,value)
 local o=Instance.new("TextLabel");o.Name=name;o.Size=size;o.Position=position;o.BackgroundTransparency=1;o.Text=value
 o.TextColor3=Color3.fromRGB(242,218,174);o.Font=Enum.Font.GothamMedium;o.TextSize=15;o.TextWrapped=true;o.Parent=parent;return o
end
function Controller.new(gui)
 local self=setmetatable({gui=gui,data=nil,spectateIndex=1,connections={},noticeUntil=0,lastPortalRound=0,lastLMSRound=0},Controller)
 gui.Enabled=true;gui.ResetOnSpawn=false
 self.heading=gui.Panel.Heading;self.timer=gui.Panel.Time
 self.info=panel(gui,"BD_Status",UDim2.new(.45,0,0,112),UDim2.new(0,12,1,-18),Vector2.new(0,1))
 local size=Instance.new("UISizeConstraint");size.MaxSize=Vector2.new(330,112);size.MinSize=Vector2.new(150,112);size.Parent=self.info
 self.identity=text(self.info,"Identity",UDim2.new(1,-16,0,29),UDim2.fromOffset(8,5),"Esperando próxima partida")
 self.health=text(self.info,"Health",UDim2.new(1,-16,0,28),UDim2.fromOffset(8,34),"")
 self.status=text(self.info,"Status",UDim2.new(1,-16,0,36),UDim2.fromOffset(8,64),"")
 self.notice=panel(gui,"BD_Notice",UDim2.new(.85,0,0,70),UDim2.new(.5,0,0,112),Vector2.new(.5,0))
 local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(650,70);limit.Parent=self.notice
 self.noticeText=text(self.notice,"Text",UDim2.new(1,-20,1,-12),UDim2.fromOffset(10,6),"");self.notice.Visible=false
 self.result=panel(gui,"BD_Results",UDim2.new(.85,0,0,155),UDim2.new(.5,0,.45,0),Vector2.new(.5,.5))
 local rlimit=Instance.new("UISizeConstraint");rlimit.MaxSize=Vector2.new(520,155);rlimit.Parent=self.result
 self.resultText=text(self.result,"Summary",UDim2.new(1,-24,1,-20),UDim2.fromOffset(12,10),"");self.resultText.TextSize=19;self.result.Visible=false
 self.spectate=Instance.new("TextButton");self.spectate.Name="BD_SpectateNext";self.spectate.Size=UDim2.fromOffset(150,42);self.spectate.Position=UDim2.new(1,-162,1,-70)
 self.spectate.Text="Ver otro jugador";self.spectate.TextSize=14;self.spectate.Font=Enum.Font.GothamMedium;self.spectate.BackgroundColor3=Color3.fromRGB(64,34,87);self.spectate.TextColor3=Color3.fromRGB(248,224,180);self.spectate.Parent=gui;self.spectate.Visible=false
 local corner=Instance.new("UICorner");corner.Parent=self.spectate
 local ability=panel(gui,"BD_FutureAbilities",UDim2.fromOffset(150,34),UDim2.new(1,-12,1,-18),Vector2.new(1,1))
 text(ability,"Placeholder",UDim2.fromScale(1,1),UDim2.fromScale(0,0),"Habilidades · próximamente").TextSize=12
 table.insert(self.connections,self.spectate.Activated:Connect(function()self.spectateIndex+=1;self:Camera()end))
 table.insert(self.connections,player.CharacterAdded:Connect(function()task.defer(function()self:Camera()end)end))
 table.insert(self.connections,RunService.RenderStepped:Connect(function()
  if not self.data then return end
  local remaining=self.data.deadline>0 and math.max(0,math.ceil(self.data.deadline-workspace:GetServerTimeNow())) or -1
  self.timer.Text=remaining<0 and "—:—" or string.format("%02d:%02d",math.floor(remaining/60),remaining%60)
  if self.notice.Visible and os.clock()>self.noticeUntil then self.notice.Visible=false end
 end))
 player.CameraMode=Enum.CameraMode.Classic;player.CameraMinZoomDistance=6;player.CameraMaxZoomDistance=24
 return self
end
function Controller:Notify(value,duration)
 self.noticeText.Text=value;self.notice.Visible=true;self.noticeUntil=os.clock()+(duration or 5)
 self.notice.BackgroundTransparency=.7;TweenService:Create(self.notice,TweenInfo.new(.2),{BackgroundTransparency=.12}):Play()
end
function Controller:Camera()
 if not self.data then return end
 local own
 for _,p in self.data.roster do if p.id==player.UserId then own=p end end
 local active=self.data.state=="ACTIVE_ROUND" or self.data.state=="LAST_SURVIVOR_STANDING"
 local observer=active and own and (own.status=="ELIMINATED" or own.status=="ESCAPED")
 local targets={}
 if observer then
  for _,p in self.data.roster do
   if p.status=="ALIVE" or p.status=="DOWNED" then
    local target=Players:GetPlayerByUserId(p.id);local hum=target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
    if hum then table.insert(targets,hum) end
   end
  end
 end
 self.spectate.Visible=observer and #targets>0 or false
 local subject=#targets>0 and targets[(self.spectateIndex-1)%#targets+1] or player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if subject and workspace.CurrentCamera then workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;workspace.CurrentCamera.CameraSubject=subject end
end
function Controller:Update(data)
 self.data=data;self.heading.Text=phaseNames[data.state] or data.state
 local own;local downed=0
 for _,p in data.roster do if p.id==player.UserId then own=p end;if p.status=="DOWNED" then downed+=1 end end
 self.identity.Text=own and ((own.role=="KILLER" and "ASESINO · ") or "SUPERVIVIENTE · ")..(own.character or "Por elegir") or "En el lobby · "..(player:GetAttribute("BDPreference") or "por elegir")
 self.health.Text=own and own.role=="SURVIVOR" and ("Salud "..math.ceil(own.health).." / "..(data.maxHealth or 100).." · Vidas "..own.lives) or own and "RAY.X · avatar provisional" or data.map
 self.status.Text=own and (statusNames[own.status] or "") or "Acércate a un cuadro para elegir"
 if downed>0 then self.status.Text=self.status.Text.." · "..downed.." necesita(n) ayuda" end
 if data.state=="WAITING_FOR_PLAYERS" and data.diagnostic~="" then
  self.status.Text="Falta un mapa válido. Consulta la guía de integración."
 end
 self.result.Visible=data.state=="ROUND_RESULTS"
 if self.result.Visible then
  local result=data.results[player.UserId] or data.results[tostring(player.UserId)]
  self.resultText.Text=(resultNames[data.aggregate] or "RESULTADOS").."\n\n"..(resultNames[result] or "Esperas la siguiente partida")
  if data.aggregate=="CANCELLED" then self.resultText.Text=self.resultText.Text.."\n"..(data.reason or "") end
 end
 if data.portalOpen and self.lastPortalRound~=data.roundId then self.lastPortalRound=data.roundId;self:Notify("¡EL CUADRO MÁGICO ESTÁ ABIERTO! Busca la salida.",6) end
 if data.state=="LAST_SURVIVOR_STANDING" and self.lastLMSRound~=data.roundId then
  self.lastLMSRound=data.roundId;local survivor,killer="",""
  for _,p in data.roster do if p.id==data.lmsSurvivorId then survivor=p.name.." · "..(p.character or "") elseif p.id==data.killerId then killer=p.name.." · RAY.X" end end
  self:Notify("ÚLTIMO SUPERVIVIENTE\n"..survivor.." contra "..killer.." · 3:37",6)
 end
 self:Camera()
end
function Controller:Destroy() for _,c in self.connections do c:Disconnect() end end
return Controller
]====],new=[====[local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local formatTime=require(game:GetService("ReplicatedStorage").BrokenDreams.Shared.TimerFormat)
local Controller={};Controller.__index=Controller
local phaseNames={
 WAITING_FOR_PLAYERS="ESPERANDO JUGADORES...",INTERMISSION="LA PARTIDA COMIENZA EN",
 ROUND_START_REQUESTED="LA PARTIDA COMIENZA EN",
 CHARACTER_SELECTION="ELIGE TU SUPERVIVIENTE",PREPARING_ROUND="PREPARANDO LA PARTIDA",
 ACTIVE_ROUND="SOBREVIVE Y BUSCA LA SALIDA",LAST_SURVIVOR_STANDING="ÚLTIMO SUPERVIVIENTE",
 ROUND_RESULTS="RESULTADOS",RETURN_TO_LOBBY="REGRESANDO AL LOBBY",
}
local resultNames={ESCAPED="ESCAPASTE",SURVIVOR_WIN="VICTORIA DE SUPERVIVIENTES",KILLER_WIN="VICTORIA DEL ASESINO",
 MIXED="RESULTADO MIXTO",DEFEAT="DERROTA",DRAW="EMPATE",CANCELLED="RONDA CANCELADA",KILLER_LEFT="EL ASESINO ABANDONÓ"}
local statusNames={ALIVE="Con vida",DOWNED="Incapacitado",ELIMINATED="Eliminado",ESCAPED="Escapaste",DISCONNECTED="Desconectado"}
local function panel(parent,name,size,position,anchor)
 local p=parent:FindFirstChild(name)
 if p then return p end
 p=Instance.new("Frame");p.Name=name;p.Size=size;p.Position=position;p.AnchorPoint=anchor;p.BackgroundColor3=Color3.fromRGB(27,17,39);p.BackgroundTransparency=.12;p.Parent=parent
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=p
 local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(175,133,67);s.Transparency=.25;s.Parent=p
 return p
end
local function text(parent,name,size,position,value)
 local o=Instance.new("TextLabel");o.Name=name;o.Size=size;o.Position=position;o.BackgroundTransparency=1;o.Text=value
 o.TextColor3=Color3.fromRGB(242,218,174);o.Font=Enum.Font.GothamMedium;o.TextSize=15;o.TextWrapped=true;o.Parent=parent;return o
end
function Controller.new(gui)
 local self=setmetatable({gui=gui,data=nil,spectateIndex=1,connections={},noticeUntil=0,lastPortalRound=0,lastLMSRound=0},Controller)
 gui.Enabled=true;gui.ResetOnSpawn=false
 self.heading=gui.Panel.Heading;self.timer=gui.Panel.Time
 self.info=panel(gui,"BD_Status",UDim2.new(.45,0,0,112),UDim2.new(0,12,1,-18),Vector2.new(0,1))
 local size=Instance.new("UISizeConstraint");size.MaxSize=Vector2.new(330,112);size.MinSize=Vector2.new(150,112);size.Parent=self.info
 self.identity=text(self.info,"Identity",UDim2.new(1,-16,0,29),UDim2.fromOffset(8,5),"Esperando próxima partida")
 self.health=text(self.info,"Health",UDim2.new(1,-16,0,28),UDim2.fromOffset(8,34),"")
 self.status=text(self.info,"Status",UDim2.new(1,-16,0,36),UDim2.fromOffset(8,64),"")
 self.notice=panel(gui,"BD_Notice",UDim2.new(.85,0,0,70),UDim2.new(.5,0,0,112),Vector2.new(.5,0))
 local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(650,70);limit.Parent=self.notice
 self.noticeText=text(self.notice,"Text",UDim2.new(1,-20,1,-12),UDim2.fromOffset(10,6),"");self.notice.Visible=false
 self.result=panel(gui,"BD_Results",UDim2.new(.85,0,0,155),UDim2.new(.5,0,.45,0),Vector2.new(.5,.5))
 local rlimit=Instance.new("UISizeConstraint");rlimit.MaxSize=Vector2.new(520,155);rlimit.Parent=self.result
 self.resultText=text(self.result,"Summary",UDim2.new(1,-24,1,-20),UDim2.fromOffset(12,10),"");self.resultText.TextSize=19;self.result.Visible=false
 self.spectate=Instance.new("TextButton");self.spectate.Name="BD_SpectateNext";self.spectate.Size=UDim2.fromOffset(150,42);self.spectate.Position=UDim2.new(1,-162,1,-70)
 self.spectate.Text="Ver otro jugador";self.spectate.TextSize=14;self.spectate.Font=Enum.Font.GothamMedium;self.spectate.BackgroundColor3=Color3.fromRGB(64,34,87);self.spectate.TextColor3=Color3.fromRGB(248,224,180);self.spectate.Parent=gui;self.spectate.Visible=false
 local corner=Instance.new("UICorner");corner.Parent=self.spectate
 local ability=panel(gui,"BD_FutureAbilities",UDim2.fromOffset(150,34),UDim2.new(1,-12,1,-18),Vector2.new(1,1))
 text(ability,"Placeholder",UDim2.fromScale(1,1),UDim2.fromScale(0,0),"Habilidades · próximamente").TextSize=12
 table.insert(self.connections,self.spectate.Activated:Connect(function()self.spectateIndex+=1;self:Camera()end))
 table.insert(self.connections,player.CharacterAdded:Connect(function()task.defer(function()self:Camera()end)end))
 table.insert(self.connections,RunService.RenderStepped:Connect(function()
  if not self.data then return end
  local remaining=self.data.deadline>0 and math.max(0,math.ceil(self.data.deadline-workspace:GetServerTimeNow())) or -1
  if self.data.countdownOnly then remaining=self.data.remainingSeconds end
  self.timer.Text=formatTime(remaining)
  if self.notice.Visible and os.clock()>self.noticeUntil then self.notice.Visible=false end
 end))
 player.CameraMode=Enum.CameraMode.Classic;player.CameraMinZoomDistance=6;player.CameraMaxZoomDistance=24
 return self
end
function Controller:Notify(value,duration)
 self.noticeText.Text=value;self.notice.Visible=true;self.noticeUntil=os.clock()+(duration or 5)
 self.notice.BackgroundTransparency=.7;TweenService:Create(self.notice,TweenInfo.new(.2),{BackgroundTransparency=.12}):Play()
end
function Controller:Camera()
 if not self.data then return end
 local own
 for _,p in self.data.roster do if p.id==player.UserId then own=p end end
 local active=self.data.state=="ACTIVE_ROUND" or self.data.state=="LAST_SURVIVOR_STANDING"
 local observer=active and own and (own.status=="ELIMINATED" or own.status=="ESCAPED")
 local targets={}
 if observer then
  for _,p in self.data.roster do
   if p.status=="ALIVE" or p.status=="DOWNED" then
    local target=Players:GetPlayerByUserId(p.id);local hum=target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
    if hum then table.insert(targets,hum) end
   end
  end
 end
 self.spectate.Visible=observer and #targets>0 or false
 local subject=#targets>0 and targets[(self.spectateIndex-1)%#targets+1] or player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if subject and workspace.CurrentCamera then workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;workspace.CurrentCamera.CameraSubject=subject end
end
function Controller:Update(data)
 self.data=data;self.heading.Text=phaseNames[data.state] or data.state
 local own;local downed=0
 for _,p in data.roster do if p.id==player.UserId then own=p end;if p.status=="DOWNED" then downed+=1 end end
 self.identity.Text=own and ((own.role=="KILLER" and "ASESINO · ") or "SUPERVIVIENTE · ")..(own.character or "Por elegir") or "En el lobby · "..(player:GetAttribute("BDPreference") or "por elegir")
 self.health.Text=own and own.role=="SURVIVOR" and ("Salud "..math.ceil(own.health).." / "..(data.maxHealth or 100).." · Vidas "..own.lives) or own and "RAY.X · avatar provisional" or data.map
 self.status.Text=own and (statusNames[own.status] or "") or "Acércate a un cuadro para elegir"
 if downed>0 then self.status.Text=self.status.Text.." · "..downed.." necesita(n) ayuda" end
 if data.state=="WAITING_FOR_PLAYERS" and data.diagnostic~="" then
  self.status.Text="Falta un mapa válido. Consulta la guía de integración."
 end
 self.result.Visible=data.state=="ROUND_RESULTS"
 if self.result.Visible then
  local result=data.results[player.UserId] or data.results[tostring(player.UserId)]
  self.resultText.Text=(resultNames[data.aggregate] or "RESULTADOS").."\n\n"..(resultNames[result] or "Esperas la siguiente partida")
  if data.aggregate=="CANCELLED" then self.resultText.Text=self.resultText.Text.."\n"..(data.reason or "") end
 end
 if data.portalOpen and self.lastPortalRound~=data.roundId then self.lastPortalRound=data.roundId;self:Notify("¡EL CUADRO MÁGICO ESTÁ ABIERTO! Busca la salida.",6) end
 if data.state=="LAST_SURVIVOR_STANDING" and self.lastLMSRound~=data.roundId then
  self.lastLMSRound=data.roundId;local survivor,killer="",""
  for _,p in data.roster do if p.id==data.lmsSurvivorId then survivor=p.name.." · "..(p.character or "") elseif p.id==data.killerId then killer=p.name.." · RAY.X" end end
  self:Notify("ÚLTIMO SUPERVIVIENTE\n"..survivor.." contra "..killer.." · 3:37",6)
 end
 self:Camera()
end
function Controller:Destroy() for _,c in self.connections do c:Disconnect() end end
return Controller
]====]},
{target=sss.BrokenDreams.RoundService,old=[====[local Players=game:GetService("Players")
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
]====],new=[====[local Players=game:GetService("Players")
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
-- Bindables exclusivos del servidor. No se abre un remote administrativo al cliente.
local function countdownRoster()
 local list={}
 for _,player in Players:GetPlayers() do table.insert(list,{id=player.UserId,name=player.DisplayName}) end
 return list -- La cuenta depende de jugadores conectados, no de la carga de sus datos de Malicia.
end
local signals=Instance.new("Folder");signals.Name="Signals";signals.Parent=script.Parent
local startRequested=Instance.new("BindableEvent");startRequested.Name="RoundStartRequested";startRequested.Parent=signals
local restartCountdown=Instance.new("BindableFunction");restartCountdown.Name="RestartLobbyCountdown";restartCountdown.Parent=signals
restartCountdown.OnInvoke=function()
 local ok=core:RestartLobbyCountdown(now(),countdownRoster())
 if ok then publishAt=0 end
 return ok
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
  countdownOnly=config.LobbyCountdownOnly,remainingSeconds=core:Remaining(now()),countdownId=core.countdownId,
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
  if not config.LobbyCountdownOnly and core.state=="WAITING_FOR_PLAYERS" and time>=retryAt and not preparing and not returning then
   candidate,diagnostic=maps:Next();diagnostic=diagnostic or "";retryAt=time+config.MapRetrySeconds
   API.SetNextMap(candidate and candidate.entry.Name or "MAPA NO DISPONIBLE",candidate and candidate.entry.Image or "")
  end
  core:Step(time,config.LobbyCountdownOnly and countdownRoster() or players,candidate~=nil)
  local request=core:TakeStartRequest()
  if request then
   -- Marcar antes de Fire: un consumidor puede reiniciar sin duplicar este evento.
   runtime:SetAttribute("LastStartRequestId",request.countdownId)
   runtime:SetAttribute("LastStartRequestAt",request.completedAt)
   startRequested:Fire(request.countdownId,request.completedAt)
   publishAt=0
  end
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
]====]},
{target=sss.BrokenDreams.RoundCore,old=[====[-- Núcleo puro: sin remotes, geometría ni reloj del cliente. now lo proporciona el servidor.
local Core = {}; Core.__index=Core
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
function Core.new(config, characters, randomIndex)
 return setmetatable({config=config, characters=characters, randomIndex=randomIndex,
  state="WAITING_FOR_PLAYERS", deadline=0, roundId=0, revision=0, roster={},
  preferences={}, queue={}, sequence=0, results={}, reason="", mapReady=false,
  portalOpen=false, lmsUsed=false, killerId=nil, lastKiller={}, intermissionOverride=nil},Core)
end
function Core:Change(state,now,duration)
 self.state=state; self.deadline=duration and now+duration or 0; self.revision+=1
end
function Core:IsActive() return self.state=="ACTIVE_ROUND" or self.state=="LAST_SURVIVOR_STANDING" end
function Core:IsLiveAt(now)
 if self:IsActive() and now>=self.deadline then self:Finish(now,"TIMEOUT");return false end
 return self:IsActive()
end
function Core:Remaining(now) return self.deadline==0 and -1 or math.max(0,math.ceil(self.deadline-now)) end
function Core:Candidates(players)
 local out={}
 for _,p in ipairs(players) do
  if finite(p.malicia) then
   if not self.queue[p.id] then self.sequence+=1; self.queue[p.id]=self.sequence end
   table.insert(out,p)
  end
 end
 table.sort(out,function(a,b) return self.queue[a.id]<self.queue[b.id] end)
 return out
end
function Core:ChooseKiller(players)
 local top=-math.huge; local tied={}
 for _,p in ipairs(players) do
  if p.malicia>top then top=p.malicia; tied={p}
  elseif p.malicia==top then table.insert(tied,p) end
 end
 -- Empate: quien menos recientemente fue asesino; azar uniforme si persiste.
 local oldest=math.huge; local finalists={}
 for _,p in ipairs(tied) do
  local last=self.lastKiller[p.id] or 0
  if last<oldest then oldest=last; finalists={p}
  elseif last==oldest then table.insert(finalists,p) end
 end
 return #finalists>0 and finalists[self.randomIndex(#finalists)] or nil
end
function Core:Select(id,name)
 if not table.find(self.characters,name) then return false,"Personaje desconocido" end
 if self.state=="WAITING_FOR_PLAYERS" or self.state=="INTERMISSION" then
  self.preferences[id]=name; self.revision+=1; return true,"Preferencia guardada"
 end
 if self.state~="CHARACTER_SELECTION" then return false,"Selección bloqueada" end
 local p=self.roster[id]
 if not p or p.role~="SURVIVOR" then return false,"Esperas la siguiente partida o eres RAY.X" end
 for otherId,other in pairs(self.roster) do
  if otherId~=id and other.character==name then return false,"Ese personaje ya está reservado" end
 end
 p.character=name; self.preferences[id]=name; self.revision+=1; return true,"Personaje reservado"
end
function Core:BeginSelection(players,now)
 local candidates=self:Candidates(players); local killer=self:ChooseKiller(candidates)
 if not killer or #candidates<self.config.MinimumPlayers then return end
 self.roundId+=1; self.killerId=killer.id; self.roster={}; self.results={}
 self.portalOpen=false; self.lmsUsed=false; self.lmsSurvivorId=nil; self.initialSurvivors=0; self.reason=""
 local function add(p,role)
  self.roster[p.id]={id=p.id,name=p.name,role=role,status="ALIVE",health=self.config.MaximumHealth,
   lives=role=="SURVIVOR" and 2 or 0, character=role=="KILLER" and "RAY.X" or nil}
 end
 add(killer,"KILLER")
 for _,p in ipairs(candidates) do
  if p.id~=killer.id and self.initialSurvivors<self.config.MaximumSurvivors then
   add(p,"SURVIVOR"); self.initialSurvivors+=1
  end
 end
 self:Change("CHARACTER_SELECTION",now,self.config.SelectionSeconds)
 -- Orden de cola para resolver preferencias repetidas sin duplicar personajes.
 for _,p in ipairs(candidates) do
  if self.preferences[p.id] then self:Select(p.id,self.preferences[p.id]) end
 end
end
function Core:FillCharacters()
 local used={}; local missing={}
 for _,p in pairs(self.roster) do
  if p.role=="SURVIVOR" then
   if p.character then used[p.character]=true else table.insert(missing,p) end
  end
 end
 table.sort(missing,function(a,b) return self.queue[a.id]<self.queue[b.id] end)
 for _,p in ipairs(missing) do
  for _,name in ipairs(self.characters) do if not used[name] then p.character=name; used[name]=true; break end end
 end
end
function Core:StartRound(now)
 if self.state~="PREPARING_ROUND" then return false end
 self.lastKiller[self.killerId]=self.roundId
 for id in pairs(self.roster) do self.sequence+=1; self.queue[id]=self.sequence end
 self:Change("ACTIVE_ROUND",now,self.config.RoundSeconds); return true
end
function Core:Abort(now,reason)
 self.reason=reason or "Ronda cancelada"; self.results={}
 for id in pairs(self.roster) do self.results[id]="CANCELLED" end
 self.aggregate="CANCELLED"; self:Change("ROUND_RESULTS",now,self.config.ResultsSeconds)
end
function Core:Survivors()
 local active={}
 for _,p in pairs(self.roster) do
  if p.role=="SURVIVOR" and (p.status=="ALIVE" or p.status=="DOWNED") then table.insert(active,p) end
 end
 return active
end
function Core:BeginLMS(now,manual)
 if not self:IsLiveAt(now) then return false end
 if self.state~="ACTIVE_ROUND" or self.lmsUsed then return false end
 local remaining=self:Survivors()
 if #remaining~=1 or remaining[1].status~="ALIVE" then return false end
 if not manual and self.initialSurvivors<2 then return false end
 self.lmsUsed=true; self.lmsSurvivorId=remaining[1].id
 self:Change("LAST_SURVIVOR_STANDING",now,self.config.LMSSeconds); return true
end
function Core:Finish(now,reason)
 if not self:IsActive() then return false end
 self.reason=reason; self.results={}; local escaped,failed=0,0
 for id,p in pairs(self.roster) do
  if p.role=="SURVIVOR" then
   local outcome
   if p.status=="ESCAPED" then outcome="ESCAPED"; escaped+=1
   elseif p.status=="ELIMINATED" or p.status=="DISCONNECTED" then outcome="DEFEAT"; failed+=1
   elseif reason=="KILLER_LEFT" and self.config.KillerDisconnectOutcome=="SURVIVOR_WIN" then outcome="SURVIVOR_WIN"
   elseif reason=="TIMEOUT" and self.config.TimeoutOutcome=="DRAW" then outcome="DRAW"
   elseif reason=="STUDIO_END" then outcome="CANCELLED"
   else outcome="DEFEAT"; failed+=1 end
   self.results[id]=outcome
  end
 end
 if reason=="STUDIO_END" then self.aggregate="CANCELLED"
 elseif reason=="KILLER_LEFT" then self.aggregate="KILLER_LEFT"
 elseif escaped>0 and failed>0 then self.aggregate="MIXED"
 elseif escaped>0 then self.aggregate="SURVIVOR_WIN"
 elseif reason=="TIMEOUT" and self.config.TimeoutOutcome=="DRAW" then self.aggregate="DRAW"
 else self.aggregate="KILLER_WIN" end
 self.results[self.killerId]=self.aggregate=="KILLER_WIN" and "KILLER_WIN"
  or self.aggregate=="CANCELLED" and "CANCELLED" or self.aggregate=="DRAW" and "DRAW" or "DEFEAT"
 self:Change("ROUND_RESULTS",now,self.config.ResultsSeconds); return true
end
function Core:Resolve(now)
 if not self:IsActive() then return end
 if #self:Survivors()==0 then self:Finish(now,"NO_SURVIVORS") else self:BeginLMS(now,false) end
end
function Core:Damage(id,amount,sourceId,now)
 if not self:IsLiveAt(now) or (sourceId~=nil and sourceId~=self.killerId) or not finite(amount) or amount<=0 then return false end
 local p=self.roster[id]
 if not p or p.role~="SURVIVOR" or p.status~="ALIVE" then return false end
 p.health=math.max(0,p.health-amount); self.revision+=1
 if p.health==0 then
  p.lives-=1
  if p.lives==1 then
   p.status="DOWNED"; p.downedBy=sourceId
   p.bleedoutAt=self.config.BleedoutSeconds and now+self.config.BleedoutSeconds or nil
  else self:Eliminate(id,sourceId,now) end
 end
 return true
end
function Core:Eliminate(id,sourceId,now)
 local p=self.roster[id]
 if not self:IsLiveAt(now) or not p or p.role~="SURVIVOR" or (p.status~="ALIVE" and p.status~="DOWNED") then return false end
 p.status="ELIMINATED";p.health=0;p.lives=0;p.bleedoutAt=nil;self.revision+=1
 if self.state=="ACTIVE_ROUND" and sourceId==self.killerId then self.deadline+=self.config.EliminationBonusSeconds end
 self:Resolve(now); return true
end
function Core:Revive(id,now)
 local p=self.roster[id]
 if not self:IsLiveAt(now) or not p or p.status~="DOWNED" then return false end
 if p.bleedoutAt and now>=p.bleedoutAt then return false end
 p.status="ALIVE";p.health=self.config.ReviveHealth;p.bleedoutAt=nil;self.revision+=1;return true
end
function Core:Escape(id,now)
 local p=self.roster[id]
 if not self:IsLiveAt(now) or not self.portalOpen or not p or p.role~="SURVIVOR" or p.status~="ALIVE" then return false end
 p.status="ESCAPED";self.revision+=1;self:Resolve(now);return true
end
function Core:Disconnect(id,now)
 self.preferences[id]=nil;self.queue[id]=nil
 local p=self.roster[id];if not p then return end
 if p.status~="ESCAPED" and p.status~="ELIMINATED" then p.status="DISCONNECTED" end
 self.revision+=1
 if self:IsActive() then
  if id==self.killerId then self:Finish(now,"KILLER_LEFT") else self:Resolve(now) end
 elseif self.state=="CHARACTER_SELECTION" or self.state=="PREPARING_ROUND" then
  if id==self.killerId or #self:Survivors()<1 then self:Abort(now,"Un participante salió durante la preparación")
  else self.roster[id]=nil;self.initialSurvivors-=1 end
 end
end
function Core:Returned(now)
 if self.state~="RETURN_TO_LOBBY" then return end
 self.roster={};self.killerId=nil;self.portalOpen=false;self.results={};self.reason=""
 self:Change("WAITING_FOR_PLAYERS",now)
end
function Core:Step(now,players,mapReady)
 self.mapReady=mapReady
 if self.state=="WAITING_FOR_PLAYERS" then
  self:Candidates(players)
  if #players>=self.config.MinimumPlayers and mapReady then
   self.reason="";self:Change("INTERMISSION",now,self.intermissionOverride or self.config.IntermissionSeconds)
  end
 elseif self.state=="INTERMISSION" then
  if #players<self.config.MinimumPlayers or not mapReady then self:Change("WAITING_FOR_PLAYERS",now)
  elseif now>=self.deadline then self:BeginSelection(players,now) end
 elseif self.state=="CHARACTER_SELECTION" then
  if #players<self.config.MinimumPlayers then self:Abort(now,"Faltan jugadores")
  elseif now>=self.deadline then self:FillCharacters();self:Change("PREPARING_ROUND",now) end
 elseif self:IsActive() then
  if now>=self.deadline then self:Finish(now,"TIMEOUT");return end
  if not self.portalOpen and self.deadline-now<=self.config.EscapeAtSeconds then self.portalOpen=true;self.revision+=1 end
  -- Resolver todos los sangrados del mismo tick antes de evaluar LMS.
  local expired={}
  for id,p in pairs(self.roster) do if p.status=="DOWNED" and p.bleedoutAt and now>=p.bleedoutAt then table.insert(expired,id) end end
  for _,id in ipairs(expired) do
   local p=self.roster[id]
   if self:IsActive() then self:Eliminate(id,p.downedBy,now) end
  end
  self:Resolve(now)
 elseif self.state=="ROUND_RESULTS" and now>=self.deadline then self:Change("RETURN_TO_LOBBY",now) end
end
return Core
]====],new=[====[-- Núcleo puro: sin remotes, geometría ni reloj del cliente. now lo proporciona el servidor.
local Core = {}; Core.__index=Core
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
function Core.new(config, characters, randomIndex)
 return setmetatable({config=config, characters=characters, randomIndex=randomIndex,
  state="WAITING_FOR_PLAYERS", deadline=0, roundId=0, revision=0, roster={},
  preferences={}, queue={}, sequence=0, results={}, reason="", mapReady=false,
  portalOpen=false, lmsUsed=false, killerId=nil, lastKiller={}, intermissionOverride=nil,
  countdownId=0, pendingStartRequest=nil},Core)
end
function Core:Change(state,now,duration)
 self.state=state; self.deadline=duration and now+duration or 0; self.revision+=1
end
function Core:IsActive() return self.state=="ACTIVE_ROUND" or self.state=="LAST_SURVIVOR_STANDING" end
function Core:IsLiveAt(now)
 if self:IsActive() and now>=self.deadline then self:Finish(now,"TIMEOUT");return false end
 return self:IsActive()
end
function Core:Remaining(now)
 if self.state=="ROUND_START_REQUESTED" then return 0 end
 return self.deadline==0 and -1 or math.max(0,math.ceil(self.deadline-now))
end
-- Consumo único: ni los Heartbeats siguientes ni un reinicio reemiten la misma señal.
function Core:TakeStartRequest()
 local request=self.pendingStartRequest;self.pendingStartRequest=nil;return request
end
function Core:RestartLobbyCountdown(now,players)
 if not self.config.LobbyCountdownOnly or (self.state~="WAITING_FOR_PLAYERS" and self.state~="INTERMISSION" and self.state~="ROUND_START_REQUESTED") then return false end
 self.pendingStartRequest=nil;self:Change("WAITING_FOR_PLAYERS",now)
 self:Step(now,players,false);return true
end
function Core:Candidates(players)
 local out={}
 for _,p in ipairs(players) do
  if finite(p.malicia) then
   if not self.queue[p.id] then self.sequence+=1; self.queue[p.id]=self.sequence end
   table.insert(out,p)
  end
 end
 table.sort(out,function(a,b) return self.queue[a.id]<self.queue[b.id] end)
 return out
end
function Core:ChooseKiller(players)
 local top=-math.huge; local tied={}
 for _,p in ipairs(players) do
  if p.malicia>top then top=p.malicia; tied={p}
  elseif p.malicia==top then table.insert(tied,p) end
 end
 -- Empate: quien menos recientemente fue asesino; azar uniforme si persiste.
 local oldest=math.huge; local finalists={}
 for _,p in ipairs(tied) do
  local last=self.lastKiller[p.id] or 0
  if last<oldest then oldest=last; finalists={p}
  elseif last==oldest then table.insert(finalists,p) end
 end
 return #finalists>0 and finalists[self.randomIndex(#finalists)] or nil
end
function Core:Select(id,name)
 if not table.find(self.characters,name) then return false,"Personaje desconocido" end
 if self.state=="WAITING_FOR_PLAYERS" or self.state=="INTERMISSION" then
  self.preferences[id]=name; self.revision+=1; return true,"Preferencia guardada"
 end
 if self.state~="CHARACTER_SELECTION" then return false,"Selección bloqueada" end
 local p=self.roster[id]
 if not p or p.role~="SURVIVOR" then return false,"Esperas la siguiente partida o eres RAY.X" end
 for otherId,other in pairs(self.roster) do
  if otherId~=id and other.character==name then return false,"Ese personaje ya está reservado" end
 end
 p.character=name; self.preferences[id]=name; self.revision+=1; return true,"Personaje reservado"
end
function Core:BeginSelection(players,now)
 local candidates=self:Candidates(players); local killer=self:ChooseKiller(candidates)
 if not killer or #candidates<self.config.MinimumPlayers then return end
 self.roundId+=1; self.killerId=killer.id; self.roster={}; self.results={}
 self.portalOpen=false; self.lmsUsed=false; self.lmsSurvivorId=nil; self.initialSurvivors=0; self.reason=""
 local function add(p,role)
  self.roster[p.id]={id=p.id,name=p.name,role=role,status="ALIVE",health=self.config.MaximumHealth,
   lives=role=="SURVIVOR" and 2 or 0, character=role=="KILLER" and "RAY.X" or nil}
 end
 add(killer,"KILLER")
 for _,p in ipairs(candidates) do
  if p.id~=killer.id and self.initialSurvivors<self.config.MaximumSurvivors then
   add(p,"SURVIVOR"); self.initialSurvivors+=1
  end
 end
 self:Change("CHARACTER_SELECTION",now,self.config.SelectionSeconds)
 -- Orden de cola para resolver preferencias repetidas sin duplicar personajes.
 for _,p in ipairs(candidates) do
  if self.preferences[p.id] then self:Select(p.id,self.preferences[p.id]) end
 end
end
function Core:FillCharacters()
 local used={}; local missing={}
 for _,p in pairs(self.roster) do
  if p.role=="SURVIVOR" then
   if p.character then used[p.character]=true else table.insert(missing,p) end
  end
 end
 table.sort(missing,function(a,b) return self.queue[a.id]<self.queue[b.id] end)
 for _,p in ipairs(missing) do
  for _,name in ipairs(self.characters) do if not used[name] then p.character=name; used[name]=true; break end end
 end
end
function Core:StartRound(now)
 if self.state~="PREPARING_ROUND" then return false end
 self.lastKiller[self.killerId]=self.roundId
 for id in pairs(self.roster) do self.sequence+=1; self.queue[id]=self.sequence end
 self:Change("ACTIVE_ROUND",now,self.config.RoundSeconds); return true
end
function Core:Abort(now,reason)
 self.reason=reason or "Ronda cancelada"; self.results={}
 for id in pairs(self.roster) do self.results[id]="CANCELLED" end
 self.aggregate="CANCELLED"; self:Change("ROUND_RESULTS",now,self.config.ResultsSeconds)
end
function Core:Survivors()
 local active={}
 for _,p in pairs(self.roster) do
  if p.role=="SURVIVOR" and (p.status=="ALIVE" or p.status=="DOWNED") then table.insert(active,p) end
 end
 return active
end
function Core:BeginLMS(now,manual)
 if not self:IsLiveAt(now) then return false end
 if self.state~="ACTIVE_ROUND" or self.lmsUsed then return false end
 local remaining=self:Survivors()
 if #remaining~=1 or remaining[1].status~="ALIVE" then return false end
 if not manual and self.initialSurvivors<2 then return false end
 self.lmsUsed=true; self.lmsSurvivorId=remaining[1].id
 self:Change("LAST_SURVIVOR_STANDING",now,self.config.LMSSeconds); return true
end
function Core:Finish(now,reason)
 if not self:IsActive() then return false end
 self.reason=reason; self.results={}; local escaped,failed=0,0
 for id,p in pairs(self.roster) do
  if p.role=="SURVIVOR" then
   local outcome
   if p.status=="ESCAPED" then outcome="ESCAPED"; escaped+=1
   elseif p.status=="ELIMINATED" or p.status=="DISCONNECTED" then outcome="DEFEAT"; failed+=1
   elseif reason=="KILLER_LEFT" and self.config.KillerDisconnectOutcome=="SURVIVOR_WIN" then outcome="SURVIVOR_WIN"
   elseif reason=="TIMEOUT" and self.config.TimeoutOutcome=="DRAW" then outcome="DRAW"
   elseif reason=="STUDIO_END" then outcome="CANCELLED"
   else outcome="DEFEAT"; failed+=1 end
   self.results[id]=outcome
  end
 end
 if reason=="STUDIO_END" then self.aggregate="CANCELLED"
 elseif reason=="KILLER_LEFT" then self.aggregate="KILLER_LEFT"
 elseif escaped>0 and failed>0 then self.aggregate="MIXED"
 elseif escaped>0 then self.aggregate="SURVIVOR_WIN"
 elseif reason=="TIMEOUT" and self.config.TimeoutOutcome=="DRAW" then self.aggregate="DRAW"
 else self.aggregate="KILLER_WIN" end
 self.results[self.killerId]=self.aggregate=="KILLER_WIN" and "KILLER_WIN"
  or self.aggregate=="CANCELLED" and "CANCELLED" or self.aggregate=="DRAW" and "DRAW" or "DEFEAT"
 self:Change("ROUND_RESULTS",now,self.config.ResultsSeconds); return true
end
function Core:Resolve(now)
 if not self:IsActive() then return end
 if #self:Survivors()==0 then self:Finish(now,"NO_SURVIVORS") else self:BeginLMS(now,false) end
end
function Core:Damage(id,amount,sourceId,now)
 if not self:IsLiveAt(now) or (sourceId~=nil and sourceId~=self.killerId) or not finite(amount) or amount<=0 then return false end
 local p=self.roster[id]
 if not p or p.role~="SURVIVOR" or p.status~="ALIVE" then return false end
 p.health=math.max(0,p.health-amount); self.revision+=1
 if p.health==0 then
  p.lives-=1
  if p.lives==1 then
   p.status="DOWNED"; p.downedBy=sourceId
   p.bleedoutAt=self.config.BleedoutSeconds and now+self.config.BleedoutSeconds or nil
  else self:Eliminate(id,sourceId,now) end
 end
 return true
end
function Core:Eliminate(id,sourceId,now)
 local p=self.roster[id]
 if not self:IsLiveAt(now) or not p or p.role~="SURVIVOR" or (p.status~="ALIVE" and p.status~="DOWNED") then return false end
 p.status="ELIMINATED";p.health=0;p.lives=0;p.bleedoutAt=nil;self.revision+=1
 if self.state=="ACTIVE_ROUND" and sourceId==self.killerId then self.deadline+=self.config.EliminationBonusSeconds end
 self:Resolve(now); return true
end
function Core:Revive(id,now)
 local p=self.roster[id]
 if not self:IsLiveAt(now) or not p or p.status~="DOWNED" then return false end
 if p.bleedoutAt and now>=p.bleedoutAt then return false end
 p.status="ALIVE";p.health=self.config.ReviveHealth;p.bleedoutAt=nil;self.revision+=1;return true
end
function Core:Escape(id,now)
 local p=self.roster[id]
 if not self:IsLiveAt(now) or not self.portalOpen or not p or p.role~="SURVIVOR" or p.status~="ALIVE" then return false end
 p.status="ESCAPED";self.revision+=1;self:Resolve(now);return true
end
function Core:Disconnect(id,now)
 self.preferences[id]=nil;self.queue[id]=nil
 local p=self.roster[id];if not p then return end
 if p.status~="ESCAPED" and p.status~="ELIMINATED" then p.status="DISCONNECTED" end
 self.revision+=1
 if self:IsActive() then
  if id==self.killerId then self:Finish(now,"KILLER_LEFT") else self:Resolve(now) end
 elseif self.state=="CHARACTER_SELECTION" or self.state=="PREPARING_ROUND" then
  if id==self.killerId or #self:Survivors()<1 then self:Abort(now,"Un participante salió durante la preparación")
  else self.roster[id]=nil;self.initialSurvivors-=1 end
 end
end
function Core:Returned(now)
 if self.state~="RETURN_TO_LOBBY" then return end
 self.roster={};self.killerId=nil;self.portalOpen=false;self.results={};self.reason=""
 self:Change("WAITING_FOR_PLAYERS",now)
end
function Core:Step(now,players,mapReady)
 self.mapReady=mapReady
 local canCount=self.config.LobbyCountdownOnly or mapReady
 if self.state=="WAITING_FOR_PLAYERS" then
  self:Candidates(players)
  if #players>=self.config.MinimumPlayers and canCount then
   self.countdownId+=1
   self.reason="";self:Change("INTERMISSION",now,self.intermissionOverride or self.config.IntermissionSeconds)
  end
 elseif self.state=="INTERMISSION" then
  if #players<self.config.MinimumPlayers or not canCount then self:Change("WAITING_FOR_PLAYERS",now)
  elseif now>=self.deadline then
   if self.config.LobbyCountdownOnly then
    self.pendingStartRequest={countdownId=self.countdownId,completedAt=now}
    self:Change("ROUND_START_REQUESTED",now)
   else self:BeginSelection(players,now) end
  end
 elseif self.state=="ROUND_START_REQUESTED" then
  if #players<self.config.MinimumPlayers then self:Change("WAITING_FOR_PLAYERS",now) end
 elseif self.state=="CHARACTER_SELECTION" then
  if #players<self.config.MinimumPlayers then self:Abort(now,"Faltan jugadores")
  elseif now>=self.deadline then self:FillCharacters();self:Change("PREPARING_ROUND",now) end
 elseif self:IsActive() then
  if now>=self.deadline then self:Finish(now,"TIMEOUT");return end
  if not self.portalOpen and self.deadline-now<=self.config.EscapeAtSeconds then self.portalOpen=true;self.revision+=1 end
  -- Resolver todos los sangrados del mismo tick antes de evaluar LMS.
  local expired={}
  for id,p in pairs(self.roster) do if p.status=="DOWNED" and p.bleedoutAt and now>=p.bleedoutAt then table.insert(expired,id) end end
  for _,id in ipairs(expired) do
   local p=self.roster[id]
   if self:IsActive() then self:Eliminate(id,p.downedBy,now) end
  end
  self:Resolve(now)
 elseif self.state=="ROUND_RESULTS" and now>=self.deadline then self:Change("RETURN_TO_LOBBY",now) end
end
return Core
]====]}
}
for _,change in changes do assert(change.target.Source==change.old,"Fuente distinta: "..change.target:GetFullName().."; no se ha escrito ningún cambio") end
local backup=Instance.new("Folder");backup.Name="BD_BackupContador_"..os.date("!%Y%m%d_%H%M%S");backup.Parent=game:GetService("ServerStorage")
backup:SetAttribute("BD_IgnoreMapDiscovery",true)
for _,change in changes do
 local source=Instance.new("StringValue");source.Name=change.target.Name;source.Value=change.old;source.Parent=backup
 change.target.Source=change.new
end
local format=Instance.new("ModuleScript");format.Name="TimerFormat";format.Source=[====[return function(seconds)
 if seconds<0 then return "—:—" end
 seconds=math.max(0,math.floor(seconds))
 return string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
end
]====];format.Parent=rs.BrokenDreams.Shared
game:GetService("ChangeHistoryService"):SetWaypoint("BROKEN DREAMS · cuenta regresiva")
print("Contador integrado. Prueba con dos clientes; no se cargarán mapas.")
