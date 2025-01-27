Config = {}

-- Coordenadas del NPC y modelo
Config.NPC = {
    model = "a_m_y_cyclist_01",
    coords = vector4(984.09, -206.03, 71.07, 237.03),
}

-- Vehiculo
Config.Vehicle = {
    model = "burrito3",
    spawnCoords = vector4(978.99, -223.78, 70.01, 332.53),
    maxDistance = 100.0
}

-- Zona de guardado
Config.Garage = {
    coords = vector3(988.31, -220.61, 69.93),
}

-- Punto de entrega
Config.DeliveryPoint = {
    doorCoords = vector4(970.93, -199.48, 73.21, 59.56), -- Coordenadas de la puerta
    npcWaitCoords = vector4(970.7, -199.46, 73.21, 58.42), -- Donde esperará el NPC (un poco alejado de la puerta)
    npcSpawnCoords = vector4(972.77, -205.64, 73.21, 56.99) -- Donde aparecerá inicialmente el NPC (dentro de la casa)
}

-- NPC de entrega
Config.DeliveryNPC = {
    model = "a_m_y_business_02"
}

-- Pago por entrega
Config.Payment = 1000