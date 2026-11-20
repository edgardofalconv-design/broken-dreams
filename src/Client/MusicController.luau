local SoundService=game:GetService("SoundService")
local Controller={};Controller.__index=Controller
function Controller.new(config,registry)
 local sound=Instance.new("Sound");sound.Name="BD_RoundMusic";sound.Volume=.35;sound.Looped=true;sound.Parent=SoundService
 return setmetatable({sound=sound,config=config,registry=registry,key=""},Controller)
end
function Controller:Update(snapshot)
 local asset=""
 if snapshot.state=="ACTIVE_ROUND" then asset=self.config.NormalMusicId
 elseif snapshot.state=="LAST_SURVIVOR_STANDING" then
  for _,p in snapshot.roster do if p.id==snapshot.lmsSurvivorId then
   local definition=self.registry.Survivors[p.character];asset=definition and definition.LMSMusicId or ""
  end end
 end
 if type(asset)~="string" or not asset:match("^rbxassetid://%d+$") then asset="" end
 local key=tostring(snapshot.roundId)..":"..snapshot.state..":"..asset
 if key==self.key then return end;self.key=key
 self.sound:Stop();self.sound.SoundId=asset
 if asset~="" then self.sound:Play() end
end
function Controller:Destroy() self.sound:Destroy() end
return Controller
