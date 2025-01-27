local QBCore = exports['qb-core']:GetCoreObject()
local spawnedNPC = nil
local spawnedDeliveryNPC = nil
local playerVehicle = nil
local isVehicleAssigned = false
local isNPCTextShown = false
local isGarageTextShown = false
local isOnDuty = false
local hasDeliveryItem = false
local currentDelivery = false
local isNPCOutside = false
local deliveryStarted = false
local knockingOnDoor = false

-- Spawnear el NPC principal
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
    SetModelAsNoLongerNeeded(npcModel)
end)

-- Interacción con el NPC principal
Citizen.CreateThread(function()
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distanceToNPC = #(playerCoords - vector3(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z))

        if distanceToNPC < 2.0 then
            if not isNPCTextShown then
                exports['qb-core']:DrawText('[E] - Camionero', 'left')
                isNPCTextShown = true
            end
            if IsControlJustPressed(0, 38) then
                if not isOnDuty and not isVehicleAssigned then
                    isOnDuty = true
                    SpawnVehicle()
                    TriggerServerEvent('delivery:server:giveStartingItem')
                    hasDeliveryItem = true
                    currentDelivery = true
                    QBCore.Functions.Notify('Has comenzado tu turno de repartidor. Ve al punto marcado en el GPS.', 'success')
                    CreateDeliveryBlip()
                elseif isOnDuty and not currentDelivery then
                    -- Finalizar trabajo y recibir pago
                    if not isVehicleAssigned then
                        isOnDuty = false
                        TriggerServerEvent('delivery:server:givePayout')
                        QBCore.Functions.Notify('Has terminado tu turno.', 'success')
                    else
                        QBCore.Functions.Notify('Primero debes devolver el vehículo.', 'error')
                    end
                else
                    QBCore.Functions.Notify('Primero debes entregar el paquete pendiente.', 'error')
                end
            end
        else
            if isNPCTextShown then
                exports['qb-core']:HideText()
                isNPCTextShown = false
            end
        end
    end
end)

-- Verificar la distancia al vehículo
Citizen.CreateThread(function()
    while true do
        if playerVehicle and isOnDuty then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local vehicleCoords = GetEntityCoords(playerVehicle)
            local distanceToVehicle = #(playerCoords - vehicleCoords)

            if distanceToVehicle > Config.Vehicle.maxDistance then
                QBCore.Functions.Notify('Tu vehículo está demasiado lejos.', 'error')
                Wait(5000)
            end
            Wait(1000)
        else
            Wait(5000)
        end
    end
end)

-- Zona para guardar el vehículo
Citizen.CreateThread(function()
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distanceToGarage = #(playerCoords - Config.Garage.coords)

        if distanceToGarage < 10.0 then
            DrawMarker(2,
                Config.Garage.coords.x, 
                Config.Garage.coords.y, 
                Config.Garage.coords.z + 0.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.3, 0.3, 0.3,
                0, 0, 0, 150,
                false,
                false,
                2,
                true,
                nil,
                nil,
                false
            )

            if distanceToGarage < 3.0 then
                if not isGarageTextShown then
                    exports['qb-core']:DrawText('[E] - Garage', 'left')
                    isGarageTextShown = true
                end
                if IsControlJustPressed(0, 38) and playerVehicle then
                    DeleteEntity(playerVehicle)
                    playerVehicle = nil
                    isVehicleAssigned = false
                    QBCore.Functions.Notify('Has guardado tu vehículo.', 'success')
                elseif IsControlJustPressed(0, 38) and not playerVehicle then
                    QBCore.Functions.Notify('No tienes un vehículo para guardar.', 'error')
                end
            else
                if isGarageTextShown then
                    exports['qb-core']:HideText()
                    isGarageTextShown = false
                end
            end
        end
    end
end)

-- Thread para el punto de entrega
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if currentDelivery and not knockingOnDoor then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distanceToDoor = #(playerCoords - vector3(Config.DeliveryPoint.doorCoords.x, Config.DeliveryPoint.doorCoords.y, Config.DeliveryPoint.doorCoords.z))

            if distanceToDoor < 2.0 and not deliveryStarted then
                exports['qb-core']:DrawText('[E] - Llamar a la puerta', 'left')
                if IsControlJustPressed(0, 38) then
                    deliveryStarted = true
                    exports['qb-core']:HideText()
                    
                    -- Animación de tocar la puerta
                    TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
                    QBCore.Functions.Notify('Llamando a la puerta...', 'primary', 3000)
                    
                    SetTimeout(3000, function()
                        ClearPedTasks(PlayerPedId())
                        MakeNPCComeOut()
                    end)
                end
            elseif isNPCOutside then
                local distanceToNPC = #(playerCoords - vector3(Config.DeliveryPoint.npcWaitCoords.x, Config.DeliveryPoint.npcWaitCoords.y, Config.DeliveryPoint.npcWaitCoords.z))
                
                if distanceToNPC < 2.0 then
                    exports['qb-core']:DrawText('[E] - Entregar paquete', 'left')
                    if IsControlJustPressed(0, 38) and hasDeliveryItem then
                        exports['qb-core']:HideText()
                        TriggerServerEvent('delivery:server:checkDeliveryItem')
                    end
                end
            end
        end
    end
end)

-- Funciones
function SpawnVehicle()
    local vehicleModel = Config.Vehicle.model
    local vehicleCoords = Config.Vehicle.spawnCoords

    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(100)
    end

    playerVehicle = CreateVehicle(vehicleModel, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, vehicleCoords.w, true, false)
    SetVehicleOnGroundProperly(playerVehicle)
    SetEntityAsMissionEntity(playerVehicle, true, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), playerVehicle, -1)
    SetVehicleDoorsLockedForAllPlayers(playerVehicle, true)
    SetVehicleDoorsLockedForPlayer(playerVehicle, PlayerId(), false)
    SetModelAsNoLongerNeeded(vehicleModel)

    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(playerVehicle))
    isVehicleAssigned = true
end

function CreateDeliveryBlip()
    local blip = AddBlipForCoord(Config.DeliveryPoint.doorCoords.x, Config.DeliveryPoint.doorCoords.y, Config.DeliveryPoint.doorCoords.z)
    SetBlipSprite(blip, 501)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    SetBlipColour(blip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Punto de entrega")
    EndTextCommandSetBlipName(blip)
end

function MakeNPCComeOut()
    local npcModel = Config.DeliveryNPC.model
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Wait(100)
    end

    local spawnCoords = Config.DeliveryPoint.npcSpawnCoords
    spawnedDeliveryNPC = CreatePed(4, npcModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, false, true)
    
    SetEntityInvincible(spawnedDeliveryNPC, true)
    SetBlockingOfNonTemporaryEvents(spawnedDeliveryNPC, true)
    FreezeEntityPosition(spawnedDeliveryNPC, false)
    SetModelAsNoLongerNeeded(npcModel)

    local waitCoords = Config.DeliveryPoint.npcWaitCoords
    ClearPedTasksImmediately(spawnedDeliveryNPC)
    TaskGoToCoordAnyMeans(spawnedDeliveryNPC, waitCoords.x, waitCoords.y, waitCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
    
    Citizen.CreateThread(function()
        local timeout = 0
        while timeout < 50 do
            local npcCoords = GetEntityCoords(spawnedDeliveryNPC)
            local dist = #(npcCoords - vector3(waitCoords.x, waitCoords.y, waitCoords.z))
            if dist < 0.5 then
                SetEntityHeading(spawnedDeliveryNPC, waitCoords.w)
                break
            end
            timeout = timeout + 1
            Wait(100)
        end
        if timeout >= 50 then
            SetEntityCoords(spawnedDeliveryNPC, waitCoords.x, waitCoords.y, waitCoords.z, false, false, false, false)
            SetEntityHeading(spawnedDeliveryNPC, waitCoords.w)
        end
    end)
    
    isNPCOutside = true
    QBCore.Functions.Notify('Alguien está saliendo...', 'primary')
end

function MakeNPCGoBack()
    if spawnedDeliveryNPC then
        local spawnCoords = Config.DeliveryPoint.npcSpawnCoords
        ClearPedTasksImmediately(spawnedDeliveryNPC)
        TaskGoToCoordAnyMeans(spawnedDeliveryNPC, spawnCoords.x, spawnCoords.y, spawnCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
        
        QBCore.Functions.Notify('El cliente está regresando a su casa...', 'primary')
        
        Citizen.CreateThread(function()
            local timeout = 0
            while timeout < 50 and DoesEntityExist(spawnedDeliveryNPC) do
                local npcCoords = GetEntityCoords(spawnedDeliveryNPC)
                local dist = #(npcCoords - vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z))
                if dist < 0.5 then
                    DeleteEntity(spawnedDeliveryNPC)
                    spawnedDeliveryNPC = nil
                    break
                end
                timeout = timeout + 1
                Wait(100)
            end
            if timeout >= 50 or DoesEntityExist(spawnedDeliveryNPC) then
                DeleteEntity(spawnedDeliveryNPC)
                spawnedDeliveryNPC = nil
            end
            isNPCOutside = false
            deliveryStarted = false
            knockingOnDoor = false
        end)
    end
end

function CleanupJob()
    if playerVehicle then
        DeleteEntity(playerVehicle)
        playerVehicle = nil
    end
    if spawnedDeliveryNPC then
        DeleteEntity(spawnedDeliveryNPC)
        spawnedDeliveryNPC = nil
    end
    isVehicleAssigned = false
    isOnDuty = false
    hasDeliveryItem = false
    currentDelivery = false
    isNPCOutside = false
    deliveryStarted = false
    knockingOnDoor = false
    
    local blip = GetFirstBlipInfoId(501)
    if blip ~= 0 then
        RemoveBlip(blip)
    end
end

-- Eventos
RegisterNetEvent('delivery:client:deliveryComplete')
AddEventHandler('delivery:client:deliveryComplete', function()
    hasDeliveryItem = false
    currentDelivery = false
    QBCore.Functions.Notify('Entrega completada. Vuelve al punto inicial.', 'success')
    RemoveBlip(GetFirstBlipInfoId(501))
    MakeNPCGoBack()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    CleanupJob()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupJob()
    end
end)