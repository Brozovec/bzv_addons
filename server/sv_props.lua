-- ZCELA NOVÝ SERVEROVÝ SKRIPT - JEDNODUCHÝ A PŘÍMOČARÝ
ESX = nil
ESX = exports['es_extended']:getSharedObject()

-- Povolené joby
local allowedJobs = {
    police = true,
    sheriff = true,
    sahp = true
}

-- Seznam objektů
local placedObjects = {}
local spikeObjects = {}

-- Kontrola oprávnění
local function hasPermission(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job then return false end
    return allowedJobs[xPlayer.job.name] or false
end

-- Do serverového souboru
RegisterNetEvent('police:registerPlacedObject')
AddEventHandler('police:registerPlacedObject', function(objectName, coords, heading, objNetId)
    local source = source
    
    -- Kontrola oprávnění
    if not hasPermission(source) then 
        return 
    end
    
    -- Pokusíme se získat entitu z netId
    local object = NetworkGetEntityFromNetworkId(objNetId)
    
    if not DoesEntityExist(object) then
        -- Pokud se nepodaří, vytvoříme objekt na serveru
        local hash = GetHashKey(objectName)
        object = CreateObject(hash, coords.x, coords.y, coords.z + 0.1, true, false, false)
        
        if not DoesEntityExist(object) then
            print("Nepodařilo se vytvořit objekt!")
            return
        end
        
        objNetId = NetworkGetNetworkIdFromEntity(object)
    end
    
    -- Nastavíme další vlastnosti
    SetEntityHeading(object, heading)
    FreezeEntityPosition(object, true)
    
    -- Uložíme informace o objektu
    local objectInfo = {
        netId = objNetId,
        type = objectName,
        heading = heading,
        coords = coords
    }
    
    table.insert(placedObjects, objectInfo)
    
    -- Pro spike objekty
    if objectName == 'p_ld_stinger_s' then
        spikeObjects[objNetId] = objectInfo
    end
    
    TriggerClientEvent('ox_lib:notify', source, {
        description = 'Objekt umístěn',
        type = 'success'
    })
end)

-- Vytvoření objektu
RegisterNetEvent('police:placeObject')
AddEventHandler('police:placeObject', function(objectName, coords, heading)
    local source = source
    
    -- Kontrola oprávnění
    if not hasPermission(source) then 
        TriggerClientEvent('ox_lib:notify', source, {
            description = 'Nemáš oprávnění k této akci!',
            type = 'error'
        })
        return 
    end
    
    -- Upravená pozice (trochu výš pro jistotu)
    local adjustedCoords = vector3(coords.x, coords.y, coords.z + 0.05)
    
    -- Pokus o vytvoření objektu - BEZ HEADINGU PRO JISTOTU
    local hash = GetHashKey(objectName)
    local object = CreateObject(hash, adjustedCoords, true, false, false)
    
    -- Zkontrolujeme, zda se objekt vytvořil
    if not DoesEntityExist(object) then
        print("Nepodařilo se vytvořit objekt: " .. objectName)
        TriggerClientEvent('ox_lib:notify', source, {
            description = 'Nepodařilo se vytvořit objekt!',
            type = 'error'
        })
        return
    end
    
    -- Nastavíme heading (NEJPROBLEMATIČTĚJŠÍ ČÁST)
    SetEntityHeading(object, heading)
    
    -- Zmrazíme objekt
    FreezeEntityPosition(object, true)
    
    -- Získáme network ID
    local netId = NetworkGetNetworkIdFromEntity(object)
    
    -- Nastavíme síťové vlastnosti
    NetworkRegisterEntityAsNetworked(object)
    SetNetworkIdCanMigrate(netId, false)
    SetNetworkIdExistsOnAllMachines(netId, true)
    
    -- Uložíme informace o objektu
    table.insert(placedObjects, {
        netId = netId,
        type = objectName,
        heading = heading,
        coords = adjustedCoords
    })
    
    -- Pro spike objekty
    if objectName == 'p_ld_stinger_s' then
        spikeObjects[netId] = {
            netId = netId,
            type = objectName,
            heading = heading,
            coords = adjustedCoords
        }
    end
    
    -- Notifikace pro hráče
    TriggerClientEvent('ox_lib:notify', source, {
        description = 'Objekt byl umístěn',
        type = 'success'
    })
end)

-- Odstranění objektu
RegisterNetEvent('police:removeObject')
AddEventHandler('police:removeObject', function(netId)
    local source = source
    
    -- Kontrola oprávnění
    if not hasPermission(source) then 
        TriggerClientEvent('ox_lib:notify', source, {
            description = 'Nemáš oprávnění k této akci!',
            type = 'error'
        })
        return 
    end
    
    -- Vyhledání objektu v seznamu
    local objectIndex = nil
    for i, obj in ipairs(placedObjects) do
        if obj.netId == netId then
            objectIndex = i
            break
        end
    end
    
    -- Pokud jsme objekt nenašli
    if not objectIndex then
        -- Zkusíme ho i tak odstranit
        local entity = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
            TriggerClientEvent('ox_lib:notify', source, {
                description = 'Objekt odstraněn',
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', source, {
                description = 'Objekt nebyl nalezen',
                type = 'error'
            })
        end
        return
    end
    
    -- Odstranění ze seznamu
    table.remove(placedObjects, objectIndex)
    
    -- Odstranění ze spike sledování
    if spikeObjects[netId] then
        spikeObjects[netId] = nil
    end
    
    -- Fyzické odstranění objektu
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
    
    -- Notifikace pro hráče
    TriggerClientEvent('ox_lib:notify', source, {
        description = 'Objekt byl odstraněn',
        type = 'success'
    })
end)

-- Propichování pneumatik
RegisterNetEvent('police:vehicleTyresBurst')
AddEventHandler('police:vehicleTyresBurst', function(vehicleNetId)
    -- Broadcast všem klientům
    TriggerClientEvent('police:burstVehicleTyres', -1, vehicleNetId)
end)

-- Při připojení hráče
RegisterNetEvent('police:requestObjects')
AddEventHandler('police:requestObjects', function()
    local source = source
    
    -- Kontrola, zda objekty stále existují
    local validObjects = {}
    for _, obj in ipairs(placedObjects) do
        local entity = NetworkGetEntityFromNetworkId(obj.netId)
        if DoesEntityExist(entity) then
            table.insert(validObjects, obj)
        end
    end
    
    -- Aktualizace seznamu objektů
    placedObjects = validObjects
end)

-- Server detekce vozidel nad spike stripy
Citizen.CreateThread(function()
    while true do
        Wait(200)
        
        -- Kontrola spike objektů
        local spikeCount = 0
        for _, _ in pairs(spikeObjects) do 
            spikeCount = spikeCount + 1 
        end
        
        if spikeCount == 0 then
            Wait(5000)
            goto continue
        end
        
        -- Kontrola vozidel nad spike objekty
        for netId, spikeInfo in pairs(spikeObjects) do
            local spikeEntity = NetworkGetEntityFromNetworkId(netId)
            
            if DoesEntityExist(spikeEntity) then
                local spikeCoords = GetEntityCoords(spikeEntity)
                
                for _, vehicle in ipairs(GetAllVehicles()) do
                    if DoesEntityExist(vehicle) then
                        local vehicleCoords = GetEntityCoords(vehicle)
                        local distance = #(vehicleCoords - spikeCoords)
                        
                        if distance < 2.5 and GetEntitySpeed(vehicle) > 0.2 then
                            local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
                            TriggerClientEvent('police:burstVehicleTyres', -1, vehicleNetId)
                            Wait(1000)
                            break
                        end
                    end
                end
            else
                -- Pokud spike neexistuje, odstraníme ho ze seznamu
                spikeObjects[netId] = nil
            end
        end
        
        ::continue::
    end
end)

-- Údržba objektů
Citizen.CreateThread(function()
    while true do
        Wait(30000) -- Každých 30 sekund
        
        local validObjects = {}
        
        for _, obj in ipairs(placedObjects) do
            local entity = NetworkGetEntityFromNetworkId(obj.netId)
            if DoesEntityExist(entity) then
                table.insert(validObjects, obj)
            end
        end
        
        -- Aktualizace seznamu objektů
        placedObjects = validObjects
    end
end)