local Service={};Service.__index=Service
function Service.new(hooks) return setmetatable({hooks=hooks,processed={}},Service) end
function Service:Deliver(core,players)
 local key=game.JobId..":"..tostring(core.roundId)
 if self.processed[key] then return end
 self.processed={[key]=true} -- una sola ronda vigente, sin crecimiento ilimitado
 for id,result in core.results do
  local player=players:GetPlayerByUserId(id)
  if player then
   player:SetAttribute("BDResult",result)
   task.spawn(function()
    local ok,err=pcall(self.hooks.OnResult,player,result,key)
    if not ok then warn("[BROKEN DREAMS] Hook de resultados: "..tostring(err)) end
   end)
  end
 end
end
return Service
