-- Sustituye solamente el controlador anterior del MISMO HUD, no crea otro temporizador.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local root=ReplicatedStorage:WaitForChild("BrokenDreams")
local client=root:WaitForChild("Client")
local gui=script.Parent
local ui=require(client.RoundUIController).new(gui)
local music=require(client.MusicController).new(require(root.Shared.GameConfig),require(root.Shared.CharacterRegistry))
local connections=require(client.CharacterSelectionController).Start(root.Remotes.Request)
table.insert(connections,root.Remotes.Snapshot.OnClientEvent:Connect(function(snapshot)
 ui:Update(snapshot);music:Update(snapshot)
end))
table.insert(connections,root.Remotes.Notice.OnClientEvent:Connect(function(message)ui:Notify(message)end))
root.Remotes.Request:FireServer("Sync")
script.Destroying:Connect(function()
 for _,connection in connections do connection:Disconnect() end
 ui:Destroy();music:Destroy()
end)
