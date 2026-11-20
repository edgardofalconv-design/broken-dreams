-- Núcleo puro: sin remotes, geometría ni reloj del cliente. now lo proporciona el servidor.
local Core = {}; Core.__index=Core
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
function Core.new(config, characters, randomIndex)
 return setmetatable({config=config, characters=characters, randomIndex=randomIndex,
  state="WAITING_FOR_PLAYERS", deadline=0, roundId=0, revision=0, roster={},
  preferences={}, queue={}, sequence=0, results={}, reason="", mapReady=false,
  portalOpen=false, lmsUsed=false, killerId=nil, lastKiller={}, intermissionOverride=nil},Core)
end
function Core:Change(state,now,duration)
 self.state=state; self.deadline=duration and now+duration or 0; self.revision+=1
end
function Core:IsActive() return self.state=="ACTIVE_ROUND" or self.state=="LAST_SURVIVOR_STANDING" end
function Core:IsLiveAt(now)
 if self:IsActive() and now>=self.deadline then self:Finish(now,"TIMEOUT");return false end
 return self:IsActive()
end
function Core:Remaining(now) return self.deadline==0 and -1 or math.max(0,math.ceil(self.deadline-now)) end
function Core:Candidates(players)
 local out={}
 for _,p in ipairs(players) do
  if finite(p.malicia) then
   if not self.queue[p.id] then self.sequence+=1; self.queue[p.id]=self.sequence end
   table.insert(out,p)
  end
 end
 table.sort(out,function(a,b) return self.queue[a.id]<self.queue[b.id] end)
 return out
end
function Core:ChooseKiller(players)
 local top=-math.huge; local tied={}
 for _,p in ipairs(players) do
  if p.malicia>top then top=p.malicia; tied={p}
  elseif p.malicia==top then table.insert(tied,p) end
 end
 -- Empate: quien menos recientemente fue asesino; azar uniforme si persiste.
 local oldest=math.huge; local finalists={}
 for _,p in ipairs(tied) do
  local last=self.lastKiller[p.id] or 0
  if last<oldest then oldest=last; finalists={p}
  elseif last==oldest then table.insert(finalists,p) end
 end
 return #finalists>0 and finalists[self.randomIndex(#finalists)] or nil
end
function Core:Select(id,name)
 if not table.find(self.characters,name) then return false,"Personaje desconocido" end
 if self.state=="WAITING_FOR_PLAYERS" or self.state=="INTERMISSION" then
  self.preferences[id]=name; self.revision+=1; return true,"Preferencia guardada"
 end
 if self.state~="CHARACTER_SELECTION" then return false,"Selección bloqueada" end
 local p=self.roster[id]
 if not p or p.role~="SURVIVOR" then return false,"Esperas la siguiente partida o eres RAY.X" end
 for otherId,other in pairs(self.roster) do
  if otherId~=id and other.character==name then return false,"Ese personaje ya está reservado" end
 end
 p.character=name; self.preferences[id]=name; self.revision+=1; return true,"Personaje reservado"
end
function Core:BeginSelection(players,now)
 local candidates=self:Candidates(players); local killer=self:ChooseKiller(candidates)
 if not killer or #candidates<self.config.MinimumPlayers then return end
 self.roundId+=1; self.killerId=killer.id; self.roster={}; self.results={}
 self.portalOpen=false; self.lmsUsed=false; self.lmsSurvivorId=nil; self.initialSurvivors=0; self.reason=""
 local function add(p,role)
  self.roster[p.id]={id=p.id,name=p.name,role=role,status="ALIVE",health=self.config.MaximumHealth,
   lives=role=="SURVIVOR" and 2 or 0, character=role=="KILLER" and "RAY.X" or nil}
 end
 add(killer,"KILLER")
 for _,p in ipairs(candidates) do
  if p.id~=killer.id and self.initialSurvivors<self.config.MaximumSurvivors then
   add(p,"SURVIVOR"); self.initialSurvivors+=1
  end
 end
 self:Change("CHARACTER_SELECTION",now,self.config.SelectionSeconds)
 -- Orden de cola para resolver preferencias repetidas sin duplicar personajes.
 for _,p in ipairs(candidates) do
  if self.preferences[p.id] then self:Select(p.id,self.preferences[p.id]) end
 end
end
function Core:FillCharacters()
 local used={}; local missing={}
 for _,p in pairs(self.roster) do
  if p.role=="SURVIVOR" then
   if p.character then used[p.character]=true else table.insert(missing,p) end
  end
 end
 table.sort(missing,function(a,b) return self.queue[a.id]<self.queue[b.id] end)
 for _,p in ipairs(missing) do
  for _,name in ipairs(self.characters) do if not used[name] then p.character=name; used[name]=true; break end end
 end
end
function Core:StartRound(now)
 if self.state~="PREPARING_ROUND" then return false end
 self.lastKiller[self.killerId]=self.roundId
 for id in pairs(self.roster) do self.sequence+=1; self.queue[id]=self.sequence end
 self:Change("ACTIVE_ROUND",now,self.config.RoundSeconds); return true
end
function Core:Abort(now,reason)
 self.reason=reason or "Ronda cancelada"; self.results={}
 for id in pairs(self.roster) do self.results[id]="CANCELLED" end
 self.aggregate="CANCELLED"; self:Change("ROUND_RESULTS",now,self.config.ResultsSeconds)
end
function Core:Survivors()
 local active={}
 for _,p in pairs(self.roster) do
  if p.role=="SURVIVOR" and (p.status=="ALIVE" or p.status=="DOWNED") then table.insert(active,p) end
 end
 return active
end
function Core:BeginLMS(now,manual)
 if not self:IsLiveAt(now) then return false end
 if self.state~="ACTIVE_ROUND" or self.lmsUsed then return false end
 local remaining=self:Survivors()
 if #remaining~=1 or remaining[1].status~="ALIVE" then return false end
 if not manual and self.initialSurvivors<2 then return false end
 self.lmsUsed=true; self.lmsSurvivorId=remaining[1].id
 self:Change("LAST_SURVIVOR_STANDING",now,self.config.LMSSeconds); return true
end
function Core:Finish(now,reason)
 if not self:IsActive() then return false end
 self.reason=reason; self.results={}; local escaped,failed=0,0
 for id,p in pairs(self.roster) do
  if p.role=="SURVIVOR" then
   local outcome
   if p.status=="ESCAPED" then outcome="ESCAPED"; escaped+=1
   elseif p.status=="ELIMINATED" or p.status=="DISCONNECTED" then outcome="DEFEAT"; failed+=1
   elseif reason=="KILLER_LEFT" and self.config.KillerDisconnectOutcome=="SURVIVOR_WIN" then outcome="SURVIVOR_WIN"
   elseif reason=="TIMEOUT" and self.config.TimeoutOutcome=="DRAW" then outcome="DRAW"
   elseif reason=="STUDIO_END" then outcome="CANCELLED"
   else outcome="DEFEAT"; failed+=1 end
   self.results[id]=outcome
  end
 end
 if reason=="STUDIO_END" then self.aggregate="CANCELLED"
 elseif reason=="KILLER_LEFT" then self.aggregate="KILLER_LEFT"
 elseif escaped>0 and failed>0 then self.aggregate="MIXED"
 elseif escaped>0 then self.aggregate="SURVIVOR_WIN"
 elseif reason=="TIMEOUT" and self.config.TimeoutOutcome=="DRAW" then self.aggregate="DRAW"
 else self.aggregate="KILLER_WIN" end
 self.results[self.killerId]=self.aggregate=="KILLER_WIN" and "KILLER_WIN"
  or self.aggregate=="CANCELLED" and "CANCELLED" or self.aggregate=="DRAW" and "DRAW" or "DEFEAT"
 self:Change("ROUND_RESULTS",now,self.config.ResultsSeconds); return true
end
function Core:Resolve(now)
 if not self:IsActive() then return end
 if #self:Survivors()==0 then self:Finish(now,"NO_SURVIVORS") else self:BeginLMS(now,false) end
end
function Core:Damage(id,amount,sourceId,now)
 if not self:IsLiveAt(now) or (sourceId~=nil and sourceId~=self.killerId) or not finite(amount) or amount<=0 then return false end
 local p=self.roster[id]
 if not p or p.role~="SURVIVOR" or p.status~="ALIVE" then return false end
 p.health=math.max(0,p.health-amount); self.revision+=1
 if p.health==0 then
  p.lives-=1
  if p.lives==1 then
   p.status="DOWNED"; p.downedBy=sourceId
   p.bleedoutAt=self.config.BleedoutSeconds and now+self.config.BleedoutSeconds or nil
  else self:Eliminate(id,sourceId,now) end
 end
 return true
end
function Core:Eliminate(id,sourceId,now)
 local p=self.roster[id]
 if not self:IsLiveAt(now) or not p or p.role~="SURVIVOR" or (p.status~="ALIVE" and p.status~="DOWNED") then return false end
 p.status="ELIMINATED";p.health=0;p.lives=0;p.bleedoutAt=nil;self.revision+=1
 if self.state=="ACTIVE_ROUND" and sourceId==self.killerId then self.deadline+=self.config.EliminationBonusSeconds end
 self:Resolve(now); return true
end
function Core:Revive(id,now)
 local p=self.roster[id]
 if not self:IsLiveAt(now) or not p or p.status~="DOWNED" then return false end
 if p.bleedoutAt and now>=p.bleedoutAt then return false end
 p.status="ALIVE";p.health=self.config.ReviveHealth;p.bleedoutAt=nil;self.revision+=1;return true
end
function Core:Escape(id,now)
 local p=self.roster[id]
 if not self:IsLiveAt(now) or not self.portalOpen or not p or p.role~="SURVIVOR" or p.status~="ALIVE" then return false end
 p.status="ESCAPED";self.revision+=1;self:Resolve(now);return true
end
function Core:Disconnect(id,now)
 self.preferences[id]=nil;self.queue[id]=nil
 local p=self.roster[id];if not p then return end
 if p.status~="ESCAPED" and p.status~="ELIMINATED" then p.status="DISCONNECTED" end
 self.revision+=1
 if self:IsActive() then
  if id==self.killerId then self:Finish(now,"KILLER_LEFT") else self:Resolve(now) end
 elseif self.state=="CHARACTER_SELECTION" or self.state=="PREPARING_ROUND" then
  if id==self.killerId or #self:Survivors()<1 then self:Abort(now,"Un participante salió durante la preparación")
  else self.roster[id]=nil;self.initialSurvivors-=1 end
 end
end
function Core:Returned(now)
 if self.state~="RETURN_TO_LOBBY" then return end
 self.roster={};self.killerId=nil;self.portalOpen=false;self.results={};self.reason=""
 self:Change("WAITING_FOR_PLAYERS",now)
end
function Core:Step(now,players,mapReady)
 self.mapReady=mapReady
 if self.state=="WAITING_FOR_PLAYERS" then
  self:Candidates(players)
  if #players>=self.config.MinimumPlayers and mapReady then
   self.reason="";self:Change("INTERMISSION",now,self.intermissionOverride or self.config.IntermissionSeconds)
  end
 elseif self.state=="INTERMISSION" then
  if #players<self.config.MinimumPlayers or not mapReady then self:Change("WAITING_FOR_PLAYERS",now)
  elseif now>=self.deadline then self:BeginSelection(players,now) end
 elseif self.state=="CHARACTER_SELECTION" then
  if #players<self.config.MinimumPlayers then self:Abort(now,"Faltan jugadores")
  elseif now>=self.deadline then self:FillCharacters();self:Change("PREPARING_ROUND",now) end
 elseif self:IsActive() then
  if now>=self.deadline then self:Finish(now,"TIMEOUT");return end
  if not self.portalOpen and self.deadline-now<=self.config.EscapeAtSeconds then self.portalOpen=true;self.revision+=1 end
  -- Resolver todos los sangrados del mismo tick antes de evaluar LMS.
  local expired={}
  for id,p in pairs(self.roster) do if p.status=="DOWNED" and p.bleedoutAt and now>=p.bleedoutAt then table.insert(expired,id) end end
  for _,id in ipairs(expired) do
   local p=self.roster[id]
   if self:IsActive() then self:Eliminate(id,p.downedBy,now) end
  end
  self:Resolve(now)
 elseif self.state=="ROUND_RESULTS" and now>=self.deadline then self:Change("RETURN_TO_LOBBY",now) end
end
return Core
