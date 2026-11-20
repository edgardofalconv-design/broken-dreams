local Service={};Service.__index=Service
function Service.new(registry,spawn,config,lobby)
 return setmetatable({registry=registry,spawn=spawn,config=config,lobby=lobby,cursor=0,active=nil},Service)
end
function Service:Find(entry)
 local found={}
 local function ignored(o)
  local current=o
  while current do
   if current:GetAttribute("BD_IgnoreMapDiscovery") or current:GetAttribute("BD_RuntimeMap") then return true end
   current=current.Parent
  end
  return false
 end
 for _,service in {workspace,game:GetService("ServerStorage")} do
  for _,o in service:GetDescendants() do
   if o:IsA("Model") and (o:GetAttribute("BDMapId")==entry.Id or o.Name==entry.Name)
    and not o:IsDescendantOf(self.lobby) and o~=self.lobby and not ignored(o) then table.insert(found,o) end
  end
 end
 if #found==1 then return found[1] end
 return nil,#found==0 and "No está construido/importado "..entry.Name or "Hay modelos duplicados para "..entry.Name
end
function Service:Structure(model)
 local folder=model:FindFirstChild("RoundSpawns");local bounds=model:FindFirstChild("PlayBounds")
 if not folder or not bounds or not bounds:IsA("BasePart") or bounds.CanCollide or not bounds.Anchored then return nil,"Faltan RoundSpawns / PlayBounds válidos" end
 local killer=folder:FindFirstChild("Killer");local escape=folder:FindFirstChild("Escape")
 local survivors=folder:FindFirstChild("Survivors")
 if not killer or not escape or not survivors then return nil,"Faltan Killer, Escape o Survivors" end
 local list=survivors:GetChildren();table.sort(list,function(a,b)return a.Name<b.Name end)
 if #list<self.config.MaximumSurvivors then return nil,"Se necesitan seis marcadores de supervivientes" end
 for _,marker in list do if not marker:IsA("BasePart") then return nil,"Survivors solo debe contener marcadores Part" end end
 return {folder=folder,bounds=bounds,killer=killer,escape=escape,survivors=list}
end
function Service:Next()
 local available={};local problems={}
 for _,entry in self.registry do
  if entry.Enabled and (not entry.StudioOnly or game:GetService("RunService"):IsStudio()) then
   local model,err=self:Find(entry)
   if model then
    local structure;structure,err=self:Structure(model)
    if structure then table.insert(available,{entry=entry,model=model}) end
   end
   if err then table.insert(problems,err) end
  end
 end
 if #available==0 then return nil,table.concat(problems,"; ") end
 self.cursor=self.cursor%#available+1;return available[self.cursor]
end
function Service:Prepare(candidate)
 self:Cleanup()
 if not candidate or not candidate.model.Parent then return nil,"Mapa no disponible" end
 local map=candidate.model;local owned=false
 if map:IsDescendantOf(game:GetService("ServerStorage")) then
  map=map:Clone();map.Name="BD_ActiveMap";map:SetAttribute("BD_RuntimeMap",true);map.Parent=workspace;owned=true
  game:GetService("RunService").Heartbeat:Wait()
 end
 self.active={model=map,owned=owned}
 local s,err=self:Structure(map);if not s then self:Cleanup();return nil,err end
 local killer;killer,err=self.spawn:Validate(map,s.killer,s.bounds)
 if not killer then self:Cleanup();return nil,"Killer: "..err end
 local escape;escape,err=self.spawn:Validate(map,s.escape,s.bounds,Vector3.new(9,10,6))
 if not escape then self:Cleanup();return nil,"Escape: "..err end
 local survivors={}
 for i=1,self.config.MaximumSurvivors do
  local point;point,err=self.spawn:Validate(map,s.survivors[i],s.bounds)
  if not point then self:Cleanup();return nil,"Survivor "..i..": "..err end
  if (point.floor-killer.floor).Magnitude<self.config.MinimumKillerSpawnSeparation then self:Cleanup();return nil,"Asesino demasiado cerca de supervivientes" end
  for _,prior in survivors do if (point.floor-prior.floor).Magnitude<5 then self:Cleanup();return nil,"Spawns de supervivientes superpuestos" end end
  survivors[i]=point
 end
 self.active.killer=killer;self.active.escape=escape;self.active.survivors=survivors;self.active.bounds=s.bounds
 return self.active
end
function Service:Cleanup()
 if self.active and self.active.owned then self.active.model:Destroy() end
 self.active=nil
end
return Service
