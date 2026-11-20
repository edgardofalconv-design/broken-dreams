local Service={};Service.__index=Service
function Service.new(config,hooks)
 return setmetatable({config=config,hooks=hooks,values={},studioOverrides={}},Service)
end
function Service:Get(player)
 if self.studioOverrides[player.UserId]~=nil then return self.studioOverrides[player.UserId] end
 local value=self.hooks.ReadMalicia(player)
 if value==nil then
  if self.values[player.UserId]==nil then self.values[player.UserId]=self.config.InitialMalicia end
  value=self.values[player.UserId]
 end
 assert(type(value)=="number" and value==value and math.abs(value)<math.huge,"Malicia del servidor inválida")
 return value
end
function Service:SetStudio(player,value)
 assert(game:GetService("RunService"):IsStudio(),"Solo Studio")
 assert(type(value)=="number" and value==value and math.abs(value)<=1e9,"Valor inválido")
 self.studioOverrides[player.UserId]=value
end
function Service:Forget(player) self.values[player.UserId]=nil;self.studioOverrides[player.UserId]=nil end
return Service
