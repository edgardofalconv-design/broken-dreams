local Service={};Service.__index=Service
function Service.new(core,players) return setmetatable({core=core,players=players,model=nil,trigger=nil},Service) end
function Service:Open(point)
 if self.model then return end
 local model=Instance.new("Model");model.Name="BD_EscapePainting"
 local origin=CFrame.lookAt(point.floor,point.floor+point.cframe.LookVector)
 local function part(name,size,offset,color,material)
  local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
  p.Size=size;p.CFrame=origin*CFrame.new(offset);p.Color=color;p.Material=material or Enum.Material.Wood;p.Parent=model;return p
 end
 local gold=Color3.fromRGB(173,116,39)
 part("FrameLeft",Vector3.new(.65,9,.8),Vector3.new(-3.3,4.6,0),gold)
 part("FrameRight",Vector3.new(.65,9,.8),Vector3.new(3.3,4.6,0),gold)
 part("FrameTop",Vector3.new(7.3,.65,.8),Vector3.new(0,9,0),gold)
 part("FrameBottom",Vector3.new(7.3,.65,.8),Vector3.new(0,.3,0),gold)
 for _,x in {-3.3,3.3} do for _,y in {.3,9} do
  local ornament=part("CarvedCorner",Vector3.new(1.1,1.1,1.1),Vector3.new(x,y,0),gold,Enum.Material.Metal);ornament.Shape=Enum.PartType.Ball
 end end
 self.trigger=part("MagicCanvas",Vector3.new(6,8,.35),Vector3.new(0,4.6,0),Color3.fromRGB(147,64,224),Enum.Material.Neon)
 self.trigger.Transparency=.32
 local light=Instance.new("PointLight");light.Color=self.trigger.Color;light.Range=16;light.Brightness=1.4;light.Shadows=false;light.Parent=self.trigger
 local particles=Instance.new("ParticleEmitter");particles.Texture="rbxasset://textures/particles/sparkles_main.dds";particles.Rate=4
 particles.Lifetime=NumberRange.new(1,2);particles.Speed=NumberRange.new(.3,.8);particles.Size=NumberSequence.new(.18)
 particles.Color=ColorSequence.new(Color3.fromRGB(206,154,255));particles.LightEmission=.8;particles.Parent=self.trigger
 local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(220,45);gui.StudsOffset=Vector3.new(0,5,0);gui.MaxDistance=140;gui.Parent=self.trigger
 local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text="EL CUADRO ESTÁ ABIERTO";label.TextColor3=Color3.fromRGB(239,210,255);label.TextScaled=true;label.Parent=gui
 model.Parent=workspace;self.model=model
end
function Service:Step(now)
 if not self.trigger or not self.core:IsActive() or now>=self.core.deadline then return end
 for id,p in self.core.roster do
  if p.role=="SURVIVOR" and p.status=="ALIVE" then
   local player=self.players:GetPlayerByUserId(id);local root=player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   if root then
    local v=self.trigger.CFrame:PointToObjectSpace(root.Position)
    if math.abs(v.X)<=3 and math.abs(v.Y)<=4 and math.abs(v.Z)<=2.2 then self.core:Escape(id,now) end
   end
  end
 end
end
function Service:Cleanup() if self.model then self.model:Destroy() end;self.model=nil;self.trigger=nil end
return Service
