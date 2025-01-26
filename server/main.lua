local QBCore = exports['qb-core']:GetCoreObject()
local Inventory = exports.origen_inventory

-- Dar item inicial
RegisterNetEvent('delivery:server:giveStartingItem')
AddEventHandler('delivery:server:giveStartingItem', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        if Inventory:AddItem(src, 'delivery_package', 1) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['delivery_package'], 'add')
            TriggerClientEvent('QBCore:Notify', src, 'Has recibido un paquete para entregar', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'No hay espacio en el inventario', 'error')
        end
    end
end)

-- Verificar entrega
RegisterNetEvent('delivery:server:checkDeliveryItem')
AddEventHandler('delivery:server:checkDeliveryItem', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        if Inventory:GetItem(src, 'delivery_package', false, false) > 0 then
            if Inventory:RemoveItem(src, 'delivery_package', 1) then
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['delivery_package'], 'remove')
                TriggerClientEvent('delivery:client:deliveryComplete', src)
                TriggerClientEvent('QBCore:Notify', src, 'Paquete entregado correctamente', 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Error al entregar el paquete', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'No tienes el paquete para entregar', 'error')
        end
    end
end)

-- Dar pago final
RegisterNetEvent('delivery:server:givePayout')
AddEventHandler('delivery:server:givePayout', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        Player.Functions.AddMoney('cash', Config.Payment, 'delivery-payment')
        TriggerClientEvent('QBCore:Notify', src, 'Has recibido $'..Config.Payment..' por tu trabajo', 'success')
    end
end)