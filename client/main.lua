local QBCore = exports['qb-core']:GetCoreObject()
local spawnedNPC = nil
local spawnedDeliveryNPC = nil
local spawnedVehicle = nil
local playerVehicle = nil
local isVehicleAssigned = false
local isNPCTextShown = false
local isGarageTextShown = false
local isOnDuty = false
local hasDeliveryItem = false
local currentDelivery = false

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
end)

-- Crear el NPC de entrega
function CreateDeliveryNPC()
    local npcModel = Config.DeliveryNPC.model
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Wait(100)
    end

    spawnedDeliveryNPC = CreatePed(4, npcModel, Config.DeliveryNPC.coords.x, Config.DeliveryNPC.coords.y, Config.DeliveryNPC.coords.z - 1.0, Config.DeliveryNPC.coords.w, false, true)
    SetEntityInvincible(spawnedDeliveryNPC, true)
    SetBlockingOfNonTemporaryEvents(spawnedDeliveryNPC, true)
    FreezeEntityPosition(spawnedDeliveryNPC, true)
end

-- Eliminar el NPC de entrega
function DeleteDeliveryNPC()
    if spawnedDeliveryNPC ~= nil then
        DeleteEntity(spawnedDeliveryNPC)
        spawnedDeliveryNPC = nil
    end
end

-- Manejar el spawn del NPC de entrega
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        if currentDelivery then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distanceToDeliveryPoint = #(playerCoords - vector3(Config.DeliveryNPC.coords.x, Config.DeliveryNPC.coords.y, Config.DeliveryNPC.coords.z))
            
            if distanceToDeliveryPoint < 30.0 and spawnedDeliveryNPC == nil then
                CreateDeliveryNPC()
            elseif distanceToDeliveryPoint > 30.0 and spawnedDeliveryNPC ~= nil then
                DeleteDeliveryNPC()
            end
        else
            if spawnedDeliveryNPC ~= nil then
                DeleteDeliveryNPC()
            end
            Wait(1000)
        end
    end
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
            if IsControlJustPressed(0, 38) then -- Tecla "E"
                if not isOnDuty and not isVehicleAssigned then
                    -- Iniciar trabajo
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
                        QBCore.Functions.Notify('Has terminado tu turno. ¡Buen trabajo!', 'success')
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
        Wait(1000)
        if playerVehicle then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local vehicleCoords = GetEntityCoords(playerVehicle)
            local distanceToVehicle = #(playerCoords - vehicleCoords)

            if distanceToVehicle > Config.Vehicle.maxDistance then
                QBCore.Functions.Notify('Tu vehículo está demasiado lejos.', 'error')
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

-- Interacción con el NPC de entrega
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if currentDelivery and spawnedDeliveryNPC then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distanceToDelivery = #(playerCoords - vector3(Config.DeliveryNPC.coords.x, Config.DeliveryNPC.coords.y, Config.DeliveryNPC.coords.z))

            if distanceToDelivery < 2.0 then
                exports['qb-core']:DrawText('[E] - Entregar paquete', 'left')
                if IsControlJustPressed(0, 38) and hasDeliveryItem then
                    TriggerServerEvent('delivery:server:checkDeliveryItem')
                end
            end
        end
        Wait(500)
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

    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(spawnedVehicle))

    isVehicleAssigned = true
end

-- Crear blip de entrega
function CreateDeliveryBlip()
    local blip = AddBlipForCoord(Config.DeliveryNPC.coords.x, Config.DeliveryNPC.coords.y, Config.DeliveryNPC.coords.z)
    SetBlipSprite(blip, 501)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    SetBlipColour(blip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Punto de entrega")
    EndTextCommandSetBlipName(blip)
end

-- Confirmar entrega exitosa
RegisterNetEvent('delivery:client:deliveryComplete')
AddEventHandler('delivery:client:deliveryComplete', function()
    hasDeliveryItem = false
    currentDelivery = false
    DeleteDeliveryNPC()
    QBCore.Functions.Notify('Entrega completada. Vuelve al punto inicial.', 'success')
    RemoveBlip(GetFirstBlipInfoId(501))
end)