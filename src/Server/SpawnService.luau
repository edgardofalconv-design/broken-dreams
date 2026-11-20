local Service={};Service.__index=Service
function Service.new(config,lobby) return setmetatable({config=config,lobby=lobby},Service) end
function Service:Validate(map,marker,bounds,clearance)
 if not marker or not marker:IsA("BasePart") or not marker.Anchored or marker.CanCollide then return nil,"Marcador inválido o con colisión" end
 local p=bounds.CFrame:PointToObjectSpace(marker.Position)
 local half=bounds.Size/2
 if math.abs(p.X)>half.X-3 or math.abs(p.Z)>half.Z-3 or math.abs(p.Y)>half.Y then return nil,"Marcador fuera de PlayBounds" end
 local exclusions={map.RoundSpawns,bounds}
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude
 local ignore=table.clone(exclusions)
 for _,pl in game:GetService("Players"):GetPlayers() do if pl.Character then table.insert(ignore,pl.Character) end end
 ray.FilterDescendantsInstances=ignore;ray.RespectCanCollide=true
 local hit=workspace:Raycast(marker.Position+Vector3.new(0,self.config.SpawnGroundRayHeight,0),
  Vector3.new(0,-self.config.SpawnGroundRayDepth,0),ray)
 if not hit or not hit.Instance:IsDescendantOf(map) or hit.Normal.Y<.8 then return nil,"Falta suelo seguro del mapa" end
 local floor=hit.Position
 -- Ningún spawn de partida puede invadir la carpa ni su bosque.
 local state=game:GetService("ReplicatedStorage"):FindFirstChild("BrokenDreamsLobbyState")
 if state then
  local origin=state:GetAttribute("Origin");local lo=state:GetAttribute("LobbyBoundsMin");local hi=state:GetAttribute("LobbyBoundsMax")
  if origin and lo and hi then
   local q=floor-origin
   if q.X>lo.X-8 and q.X<hi.X+8 and q.Z>lo.Z-8 and q.Z<hi.Z+8 then return nil,"El mapa invade el lobby" end
  end
 end
 local size=clearance or Vector3.new(unpack(self.config.SpawnClearance))
 -- Comprueba soporte bajo las cuatro esquinas, no solo un punto sobre un borde.
 for _,dx in {-size.X/2,size.X/2} do for _,dz in {-size.Z/2,size.Z/2} do
  local support=workspace:Raycast(floor+Vector3.new(dx,2,dz),Vector3.new(0,-4,0),ray)
  if not support or not support.Instance:IsDescendantOf(map) or support.Normal.Y<.8 or math.abs(support.Position.Y-floor.Y)>1 then return nil,"Suelo discontinuo junto al marcador" end
 end end
 local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Exclude
 overlap.FilterDescendantsInstances=ignore;overlap.RespectCanCollide=true
 local cf=CFrame.new(floor+Vector3.new(0,size.Y/2+.15,0))
 for _,part in workspace:GetPartBoundsInBox(cf,size,overlap) do
  if part.CanCollide then return nil,"Volumen de aparición obstruido: "..part.Name end
 end
 local forward=marker.CFrame.LookVector*Vector3.new(1,0,1)
 if forward.Magnitude<.1 then forward=Vector3.new(0,0,-1) end
 return {floor=floor,cframe=CFrame.lookAt(floor+Vector3.new(0,3.5,0),floor+Vector3.new(0,3.5,0)+forward)}
end
function Service:Teleport(player,cf)
 local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
 local hum=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health<=0 then return false,"Avatar no disponible" end
 character:PivotTo(cf);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
 return true
end
function Service:LobbyCFrame(index)
 local spawn=self.lobby.PlayerSpawns.LobbySpawn
 -- El acceso tiene espacio abierto; pequeños offsets evitan apilar avatares.
 return spawn.CFrame*CFrame.new(((index or 1)-1)%3*3-3,4,math.floor(((index or 1)-1)/3)*3)
end
return Service
