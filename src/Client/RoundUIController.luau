local Players=game:GetService("Players")
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
