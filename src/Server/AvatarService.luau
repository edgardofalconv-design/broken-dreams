local Service={};Service.__index=Service
function Service.new(config,registry)
 return setmetatable({config=config,registry=registry,saved={},loading={}},Service)
end
function Service:Save(player)
 local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local root=c and c:FindFirstChild("HumanoidRootPart")
 if h and root and not self.saved[player.UserId] then
  local archivable=c.Archivable;c.Archivable=true
  local snapshot=c:Clone();c.Archivable=archivable
  self.saved[player.UserId]={WalkSpeed=h.WalkSpeed,JumpPower=h.JumpPower,JumpHeight=h.JumpHeight,
   AutoRotate=h.AutoRotate,UseJumpPower=h.UseJumpPower,MaxHealth=h.MaxHealth,Anchored=root.Anchored}
  self.saved[player.UserId].Snapshot=snapshot
 end
end
function Service:Load(player,record)
 if self.loading[player.UserId] then return false,"El avatar todavía está cargando" end
 self.loading[player.UserId]=true
 local done,ok,err=false,false,nil
 task.spawn(function()
  ok,err=pcall(function()
   local definition=record and (record.role=="KILLER" and self.registry.Killer or self.registry.Survivors[record.character])
   local modelName=definition and definition.ModelName or ""
   local temporaryTemplate=record and self.saved[player.UserId] and self.saved[player.UserId].Snapshot
   if modelName~="" or temporaryTemplate then
    local folder=game:GetService("ServerStorage"):FindFirstChild("BrokenDreamsCharacters")
    local template=temporaryTemplate
    if modelName~="" then template=folder and folder:FindFirstChild(modelName) end
    assert(template and template:FindFirstChildOfClass("Humanoid") and template:FindFirstChild("HumanoidRootPart"),"Modelo personalizado incompleto: "..modelName)
    local avatar=template:Clone();avatar.Name=player.Name
    local old=player.Character;player.Character=avatar;avatar.Parent=workspace
    if old then old:Destroy() end
   else player:LoadCharacterAsync() end
  end)
  self.loading[player.UserId]=nil;done=true
 end)
 local endAt=os.clock()+self.config.CharacterLoadTimeout
 repeat task.wait(.05) until done or not player.Parent or os.clock()>=endAt
 if not done then return false,"Tiempo agotado cargando avatar" end
 if not ok then return false,tostring(err) end
 local c=player.Character
 if not c or not c:FindFirstChildOfClass("Humanoid") or not c:FindFirstChild("HumanoidRootPart") then return false,"Avatar sin Humanoid / root" end
 if record and record.role=="KILLER" then
  local highlight=Instance.new("Highlight");highlight.Name="BD_KillerPlaceholder";highlight.FillColor=Color3.fromRGB(155,35,190)
  highlight.FillTransparency=.65;highlight.OutlineColor=Color3.fromRGB(255,65,65);highlight.DepthMode=Enum.HighlightDepthMode.Occluded;highlight.Parent=c
  local tag=Instance.new("BillboardGui");tag.Name="BD_RoleLabel";tag.Size=UDim2.fromOffset(160,36);tag.StudsOffset=Vector3.new(0,3,0);tag.MaxDistance=60;tag.Adornee=c.HumanoidRootPart;tag.Parent=c
  local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text="RAY.X · PROVISIONAL";label.TextColor3=Color3.fromRGB(255,100,130);label.TextScaled=true;label.Parent=tag
 end
 return true
end
function Service:Restore(player)
 local saved=self.saved[player.UserId]
 if not saved or not player.Parent then return false end
 if saved.Snapshot then
  local old=player.Character;local restored=saved.Snapshot;saved.Snapshot=nil
  restored.Name=player.Name;player.Character=restored;restored.Parent=workspace
  if old then old:Destroy() end
 end
 local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local root=c and c:FindFirstChild("HumanoidRootPart")
 if saved and h and root then
  for key,value in saved do if key~="Anchored" and key~="Snapshot" then h[key]=value end end
  root.Anchored=saved.Anchored;h.Health=h.MaxHealth
 end
 self.saved[player.UserId]=nil
 return h~=nil and root~=nil
end
function Service:Forget(id)
 local saved=self.saved[id]
 if saved and saved.Snapshot then saved.Snapshot:Destroy() end
 self.saved[id]=nil
end
return Service
