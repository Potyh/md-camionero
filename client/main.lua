local spawnedNPC = nil
local spawnedVehicle = nil
local playerVehicle = nil
local isVehicleAssigned = false -- Bandera para verificar si un vehículo está asignado

-- Spawnear el NPC
Citizen.CreateThread(function()
    local npcModel = Config.NPC.model
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Wait(100)
    end

    spawnedNPC = CreatePed(4, npcModel, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.coords.w, false, true)
    SetEntityInvincible(spawnedNPC, true)
    SetBlockingOfNonTemporaryEvents(spawnedNPC, true)
    FreezeEntityPosition(spawnedNPC, true)
end)

-- Interacción con el NPC
Citizen.CreateThread(function()
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distanceToNPC = #(playerCoords - vector3(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z))

        if distanceToNPC < 2.0 then
            DrawText3D(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z + 1.0, Config.NPC.text)
            if IsControlJustPressed(0, 38) then -- Tecla "E"
                if isVehicleAssigned then
                    TriggerEvent('chat:addMessage', { args = { '[NPC]', '¡Ya tienes un vehículo asignado! Devuélvelo primero antes de sacar otro.' } })
                else
                    SpawnVehicle()
                    TriggerEvent('chat:addMessage', { args = { '[NPC]', 'Aquí tienes tu vehículo.' } })
                end
            end
        end
    end
end)

-- Verificar la distancia al vehículo
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        if playerVehicle then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local vehicleCoords = GetEntityCoords(playerVehicle)
            local distanceToVehicle = #(playerCoords - vehicleCoords)

            if distanceToVehicle > Config.Vehicle.maxDistance then
                TriggerEvent('chat:addMessage', { args = { '[SISTEMA]', 'Tu vehículo está demasiado lejos.' } })
            end
        end
    end
end)

-- Zona para guardar el vehículo
Citizen.CreateThread(function()
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distanceToGarage = #(playerCoords - Config.Garage.coords)

        if distanceToGarage < 3.0 then
            DrawText3D(Config.Garage.coords.x, Config.Garage.coords.y, Config.Garage.coords.z + 1.0, Config.Garage.text)
            if IsControlJustPressed(0, 38) and playerVehicle then
                DeleteEntity(playerVehicle)
                playerVehicle = nil
                isVehicleAssigned = false
                TriggerEvent('chat:addMessage', { args = { '[GARAGE]', 'Has guardado tu vehículo. Ahora puedes sacar otro si lo necesitas.' } })
            elseif IsControlJustPressed(0, 38) and not playerVehicle then
                TriggerEvent('chat:addMessage', { args = { '[GARAGE]', 'No tienes un vehículo para guardar.' } })
            end
        end
    end
end)

-- Función para generar el vehículo
function SpawnVehicle()
    local vehicleModel = Config.Vehicle.model
    local vehicleCoords = Config.Vehicle.spawnCoords

    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(100)
    end

    spawnedVehicle = CreateVehicle(vehicleModel, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleCoords.w, true, false)
    SetVehicleOnGroundProperly(spawnedVehicle)
    SetEntityAsMissionEntity(spawnedVehicle, true, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), spawnedVehicle, -1)
    playerVehicle = spawnedVehicle
    SetVehicleDoorsLockedForAllPlayers(spawnedVehicle, true)
    SetVehicleDoorsLockedForPlayer(spawnedVehicle, PlayerId(), false)

    -- Dar llaves con QBCore
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(spawnedVehicle))

    isVehicleAssigned = true
end

-- Dibujar texto en 3D
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
