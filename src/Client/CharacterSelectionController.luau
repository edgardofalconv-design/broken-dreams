local Prompts=game:GetService("ProximityPromptService")
local Controller={}
function Controller.Start(request)
 local connections={}
 table.insert(connections,Prompts.PromptButtonHoldBegan:Connect(function(prompt)
  if prompt.Name=="BD_Revive" then request:FireServer("ReviveBegin",prompt:GetAttribute("TargetUserId")) end
 end))
 table.insert(connections,Prompts.PromptButtonHoldEnded:Connect(function(prompt)
  if prompt.Name=="BD_Revive" then request:FireServer("ReviveCancel") end
 end))
 -- Los cuadros conservan su geometría: sus ProximityPrompts se conectan directamente en servidor.
 return connections
end
return Controller
