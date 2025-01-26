local spawnedNPC = nil
local isNearNPC = false

-- Crear el NPC
Citizen.CreateThread(function()
    local npcModel = Config.NPC.model
    local npcCoords = Config.NPC.coords

    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Wait(100)
    end

    spawnedNPC = CreatePed(4, npcModel, npcCoords.x, npcCoords.y, npcCoords.z - 1.0, npcCoords.w, false, true)
    SetEntityInvincible(spawnedNPC, true)
    SetBlockingOfNonTemporaryEvents(spawnedNPC, true)
    FreezeEntityPosition(spawnedNPC, true)
end)

-- Detectar si el jugador está cerca del NPC
Citizen.CreateThread(function()
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - vector3(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z))

        if distance < 2.0 then
            isNearNPC = true
            DrawText3D(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z + 1.0, Config.NPC.text)
            if IsControlJustPressed(0, 38) then -- Tecla "E"
                TriggerEvent('chat:addMessage', { args = { '[NPC]', 'No hay trabajo ahora.' } })
            end
        else
            isNearNPC = false
        end
    end
end)

-- DrawText3D - Texto
function DrawText3D(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end
