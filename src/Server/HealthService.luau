-- Fuente de salud: RoundCore en el servidor. Las habilidades futuras llaman Damage.
-- Humanoid se mantiene con >=1 durante DOWNED, sin depender de revivir un Humanoid muerto.
local Service={};Service.__index=Service
function Service.new(core,avatar,onDeath)
 return setmetatable({core=core,avatar=avatar,onDeath=onDeath,bindings={}},Service)
end
function Service:Unbind(id)
 local b=self.bindings[id];if b then for _,c in b.connections do c:Disconnect() end;self.bindings[id]=nil end
end
function Service:Bind(player)
 self:Unbind(player.UserId)
 local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local root=c and c:FindFirstChild("HumanoidRootPart")
 if not h or not root then return false end
 local b={connections={},writing=false,previous=self.core.config.MaximumHealth,root=root,humanoid=h,character=c};self.bindings[player.UserId]=b
 h.BreakJointsOnDeath=false
 -- El daño externo es ambiental: no puede fabricar una eliminación atribuida a RAY.X.
 table.insert(b.connections,h.HealthChanged:Connect(function(value)
  if b.writing or not self.core:IsActive() then return end
  local record=self.core.roster[player.UserId]
  if record and record.role=="SURVIVOR" and value<b.previous and record.status=="ALIVE" then
   self.core:Damage(player.UserId,b.previous-value,nil,workspace:GetServerTimeNow())
  end
  self:Sync(player)
 end))
 table.insert(b.connections,h.Died:Connect(function()
  if self.core:IsActive() then self.onDeath(player,root.CFrame) end
 end))
 self:Sync(player);return true
end
function Service:Sync(player)
 local p=self.core.roster[player.UserId];local b=self.bindings[player.UserId]
 if not b or not p or not b.character.Parent then return end
 local h,root=b.humanoid,b.root;local active=self.core:IsActive()
 local down=p.status=="DOWNED";local frozen=not active or down
 local out=p.status=="ELIMINATED" or p.status=="ESCAPED" or p.status=="DISCONNECTED"
 if out then frozen=false end
 local original=self.avatar.saved[player.UserId]
 local walk=original and original.WalkSpeed or 16
 local jump=original and original.JumpPower or 50
 local height=original and original.JumpHeight or 7.2
 h.WalkSpeed=frozen and 0 or walk;h.JumpPower=frozen and 0 or jump;h.JumpHeight=frozen and 0 or height;h.AutoRotate=not frozen
 root.Anchored=frozen
 if down then
  h.Sit=true
  if not b.character:FindFirstChild("BD_NeedsHelp") then
   local gui=Instance.new("BillboardGui");gui.Name="BD_NeedsHelp";gui.Size=UDim2.fromOffset(180,42);gui.StudsOffset=Vector3.new(0,3,0);gui.MaxDistance=90;gui.Adornee=root;gui.Parent=b.character
   local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.Text="NECESITA AYUDA";text.TextColor3=Color3.fromRGB(255,213,107);text.BackgroundTransparency=1;text.TextScaled=true;text.Parent=gui
  end
 else
  local help=b.character:FindFirstChild("BD_NeedsHelp");if help then help:Destroy();h.Sit=false end
 end
 b.writing=true
 h.MaxHealth=self.core.config.MaximumHealth
 local health=out and h.MaxHealth or math.max(1,p.health)
 if h.Health>0 and h.Health~=health then h.Health=health end
 b.previous=health;b.writing=false
 player:SetAttribute("BDHealth",p.health);player:SetAttribute("BDLives",p.lives);player:SetAttribute("BDStatus",p.status)
end
function Service:Damage(target,amount,killer)
 local now=workspace:GetServerTimeNow()
 -- Cierra primero la ronda si el plazo ya terminó.
 if self.core:IsActive() and now>=self.core.deadline then self.core:Finish(now,"TIMEOUT");return false end
 return self.core:Damage(target.UserId,amount,killer and killer.UserId or nil,now)
end
function Service:Cleanup()
 local ids={};for id in self.bindings do table.insert(ids,id) end
 for _,id in ids do self:Unbind(id) end
end
return Service
