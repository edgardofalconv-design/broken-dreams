local Limiter={};Limiter.__index=Limiter
function Limiter.new(capacity,refill) return setmetatable({capacity=capacity,refill=refill,buckets={}},Limiter) end
function Limiter:Allow(id,now)
 local b=self.buckets[id] or {tokens=self.capacity,time=now};self.buckets[id]=b
 b.tokens=math.min(self.capacity,b.tokens+math.max(0,now-b.time)*self.refill);b.time=now
 if b.tokens<1 then return false end;b.tokens-=1;return true
end
function Limiter:Forget(id) self.buckets[id]=nil end
return Limiter
