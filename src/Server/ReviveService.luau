-- El cliente solo comunica empezar/cancelar. Nunca comunica cuánto tiempo mantuvo la acción.
local Service={};Service.__index=Service
function Service.new(core,config,players)
 return setmetatable({core=core,config=config,players=players,sessions={},prompts={}},Service)
end
function Service:Valid(actorId,targetId)
 if actorId==targetId or not self.core:IsActive() then return false end
 local a,b=self.core.roster[actorId],self.core.roster[targetId]
 if not a or not b or a.role~="SURVIVOR" or a.status~="ALIVE" or b.status~="DOWNED" then return false end
 local pa,pb=self.players:GetPlayerByUserId(actorId),self.players:GetPlayerByUserId(targetId)
 local ra=pa and pa.Character and pa.Character:FindFirstChild("HumanoidRootPart")
 local rb=pb and pb.Character and pb.Character:FindFirstChild("HumanoidRootPart")
 if not ra or not rb or (ra.Position-rb.Position).Magnitude>self.config.ReviveDistance then return false end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={pa.Character,pb.Character};params.RespectCanCollide=true
 if workspace:Raycast(ra.Position,rb.Position-ra.Position,params) then return false end
 return true
end
function Service:Begin(actorId,targetId,now)
 if self:Valid(actorId,targetId) then self.sessions[actorId]={target=targetId,started=now,round=self.core.roundId};return true end
 return false
end
function Service:Cancel(actorId) self.sessions[actorId]=nil end
function Service:Step(now)
 for actorId,s in self.sessions do
  if s.round~=self.core.roundId or not self:Valid(actorId,s.target) then self.sessions[actorId]=nil
  elseif now-s.started>=self.config.ReviveSeconds then self.core:Revive(s.target,now);self.sessions[actorId]=nil end
 end
 for id,p in self.core.roster do
  local player=self.players:GetPlayerByUserId(id)
  local root=player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local old=self.prompts[id]
  if old and (p.status~="DOWNED" or not self.core:IsActive() or old.Parent~=root) then old:Destroy();self.prompts[id]=nil end
  if p.status=="DOWNED" and self.core:IsActive() and root and not self.prompts[id] then
   local prompt=Instance.new("ProximityPrompt");prompt.Name="BD_Revive";prompt.ActionText="Reanimar";prompt.ObjectText=player.DisplayName
   prompt:SetAttribute("TargetUserId",id);prompt.HoldDuration=self.config.ReviveSeconds+.2;prompt.MaxActivationDistance=self.config.ReviveDistance;prompt.RequiresLineOfSight=true
   prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.Parent=root;self.prompts[id]=prompt
   -- La interacción se temporiza en Begin/Cancel a través del remote validado.
  end
 end
end
function Service:Cleanup()
 self.sessions={};for _,p in self.prompts do p:Destroy() end;self.prompts={}
end
return Service
