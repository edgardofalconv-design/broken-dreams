return function(seconds)
 if seconds<0 then return "—:—" end
 seconds=math.max(0,math.floor(seconds))
 return string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
end
