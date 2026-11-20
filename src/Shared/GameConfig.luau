-- Todos los tiempos son segundos. Solo el servidor decide los valores efectivos.
return {
 LobbyCountdownOnly = true, -- Señal interna al llegar a cero; sin cargar ni teletransportar a mapas.
 MinimumPlayers = 2,
 MaximumSurvivors = 6,
 IntermissionSeconds = 30, -- Provisional
 SelectionSeconds = 15, -- Provisional
 RoundSeconds = 355,
 EliminationBonusSeconds = 10,
 LMSSeconds = 217,
 EscapeAtSeconds = 80,
 ResultsSeconds = 8, -- Provisional
 MaximumHealth = 100,
 ReviveHealth = 50, -- Provisional
 ReviveSeconds = 4, -- Provisional
 ReviveDistance = 9,
 BleedoutSeconds = 45, -- Provisional; false desactiva el sangrado
 TimeoutOutcome = "DEFEAT", -- Alternativa de prueba: DRAW
 KillerDisconnectOutcome = "SURVIVOR_WIN", -- Política provisional, sin fingir escapes
 InitialMalicia = 0, -- Temporal, por sesión. No se inventa una economía ni persistencia.
 MapRetrySeconds = 5,
 SelectionDistance = 16,
 SpawnGroundRayHeight = 5,
 SpawnGroundRayDepth = 20,
 SpawnClearance = {4, 6, 4},
 MinimumKillerSpawnSeparation = 24,
 CharacterLoadTimeout = 12,
 StudioToolsEnabled = true, -- Además requiere RunService:IsStudio() en el servidor.
 StudioDamage = 100,
 NormalMusicId = "", -- rbxassetid://ID real autorizado; vacío = silencio
}
