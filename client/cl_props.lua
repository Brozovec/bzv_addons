-- ZCELA NOVÝ KLIENTSKÝ SKRIPT - JEDNODUCHÝ A PŘÍMOČARÝ
ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports['es_extended']:getSharedObject()
        Citizen.Wait(0)
    end
end)

-- Globální proměnné
local previewObject = nil
local isPreviewing = false
local nearObject = nil
local isNearObject = false

-- Povolené joby
local allowedJobs = {
    police = true,
    sheriff = true,
    sahp = true
}

-- Kontrola jobu
function hasPermission()
    local playerData = ESX.GetPlayerData()
    if not playerData or not playerData.job then return false end
    return allowedJobs[playerData.job.name] or false
end

-- Animace
function playPlaceAnimation()
    local dict = 'amb@world_human_gardener_plant@male@enter'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end

    TaskPlayAnim(PlayerPedId(), dict, 'enter', 8.0, -8.0, 1500, 1, 0, false, false, false)
    Wait(1500)
    ClearPedTasks(PlayerPedId())
end

-- Propichování pneumatik
RegisterNetEvent('police:burstVehicleTyres')
AddEventHandler('police:burstVehicleTyres', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if DoesEntityExist(vehicle) then
        for i = 0, 7 do
            SetVehicleTyreBurst(vehicle, i, false, 1000.0)
        end
        
        PlaySoundFromEntity(-1, "TIRE_PUNCTURE", vehicle, "ASSASSINATIONS_HOTEL_SOUND_SET", 0, 0)
    end
end)

-- Spike strip detekce
Citizen.CreateThread(function() 
    while true do
        Wait(200)
        
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 and GetEntitySpeed(vehicle) > 0.5 then
            local pos = GetEntityCoords(vehicle)
            
            local objects = GetGamePool('CObject')
            for _, obj in ipairs(objects) do
                local model = GetEntityModel(obj)
                if model == GetHashKey('p_ld_stinger_s') then
                    local spikPos = GetEntityCoords(obj)
                    local dist = #(pos - spikPos)
                    
                    if dist < 2.5 then
                        local vehNetId = NetworkGetNetworkIdFromEntity(vehicle)
                        TriggerServerEvent('police:vehicleTyresBurst', vehNetId)
                        Wait(2000)
                        break
                    end
                end
            end
        end
        
        Wait(10)
    end
end)

-- Detekce blízkých objektů pro zvednutí
Citizen.CreateThread(function()
    while true do
        Wait(500)
        
        -- Pouze pro státní složky
        if not hasPermission() then 
            if isNearObject then
                lib.hideTextUI()
                isNearObject = false
                nearObject = nil
            end
            Wait(1000)
            goto continue
        end
        
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        
        -- Hledáme nejbližší policejní objekt
        local foundObject = nil
        local foundDistance = 999.0
        local foundNetId = nil
        
        local objects = GetGamePool('CObject')
        for _, obj in ipairs(objects) do
            local model = GetEntityModel(obj)
            
            if model == GetHashKey('prop_barrier_work05') or
               model == GetHashKey('prop_roadcone02a') or
               model == GetHashKey('p_ld_stinger_s') then
                
                local objCoords = GetEntityCoords(obj)
                local distance = #(coords - objCoords)
                
                if distance < 2.0 and distance < foundDistance then
                    local netId = NetworkGetNetworkIdFromEntity(obj)
                    if netId ~= 0 then
                        foundObject = obj
                        foundDistance = distance
                        foundNetId = netId
                    end
                end
            end
        end
        
        -- Zobrazení/skrytí UI
        if foundObject and not isNearObject then
            isNearObject = true
            nearObject = foundNetId
            
            lib.showTextUI('[E] Zvednout objekt', {
                position = "right-center",
                icon = 'hand',
            })
        elseif not foundObject and isNearObject then
            isNearObject = false
            nearObject = nil
            lib.hideTextUI()
        elseif foundObject and isNearObject then
            nearObject = foundNetId
        end
        
        ::continue::
    end
end)

-- Zvedání objektů
Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        if isNearObject and nearObject then
            if IsControlJustPressed(0, 38) then -- E
                TriggerServerEvent('police:removeObject', nearObject)
                Wait(500)
            end
        else
            Wait(500)
        end
    end
end)

-- Vytváření objektů
-- Do klientského souboru
RegisterNetEvent('police:startPlacingObject')
AddEventHandler('police:startPlacingObject', function(data)
    if not hasPermission() then return end
    
    local objectName = data.object
    local hash = GetHashKey(objectName)
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    
    local heading = 0.0
    local playerPed = PlayerPedId()
    local forward = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.5, 0.0)
    
    if previewObject and DoesEntityExist(previewObject) then
        DeleteEntity(previewObject)
    end
    
    previewObject = CreateObject(hash, forward.x, forward.y, forward.z, false, false, false)
    SetEntityAlpha(previewObject, 150, false)
    SetEntityCollision(previewObject, false, false)
    FreezeEntityPosition(previewObject, true)
    isPreviewing = true
    
    lib.showTextUI('[E] Umístit | [←][→] Otočit | [BACKSPACE] Zrušit')
    
    Citizen.CreateThread(function()
        while isPreviewing do
            Wait(0)
            
            playerPed = PlayerPedId()
            forward = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.5, 0.0)
            local hit, groundZ = GetGroundZFor_3dCoord(forward.x, forward.y, forward.z + 1.0, true)
            
            if hit then
                -- Rotace
                if IsControlPressed(0, 174) then -- Šipka doleva
                    heading = heading - 1.0
                elseif IsControlPressed(0, 175) then -- Šipka doprava
                    heading = heading + 1.0
                end
                
                SetEntityCoords(previewObject, forward.x, forward.y, groundZ + 0.1, false, false, false, false)
                SetEntityHeading(previewObject, heading)
                
                if IsControlJustReleased(0, 38) then -- E
                    local clientHeading = GetEntityHeading(previewObject)
                    
                    DeleteEntity(previewObject)
                    previewObject = nil
                    isPreviewing = false
                    lib.hideTextUI()
                    
                    playPlaceAnimation()
                    
                    -- VYTVOŘÍME OBJEKT HNED LOKÁLNĚ
                    local localObj = CreateObject(hash, forward.x, forward.y, groundZ + 0.1, true, true, true)
                    if DoesEntityExist(localObj) then
                        -- Nastavíme správný heading ihned
                        SetEntityHeading(localObj, clientHeading)
                        FreezeEntityPosition(localObj, true)
                        
                        -- Odešleme na server s headingem
                        local objNetId = NetworkGetNetworkIdFromEntity(localObj)
                        TriggerServerEvent('police:registerPlacedObject', objectName, vector3(forward.x, forward.y, groundZ), clientHeading, objNetId)
                    else
                        -- Pokud se nepodaří vytvořit lokálně, zkusíme server
                        TriggerServerEvent('police:placeObject', objectName, vector3(forward.x, forward.y, groundZ), clientHeading)
                    end
                    return
                end
                
                if IsControlJustReleased(0, 194) then -- Backspace
                    DeleteEntity(previewObject)
                    previewObject = nil
                    isPreviewing = false
                    lib.hideTextUI()
                    return
                end
            end
        end
    end)
end)

-- Menu
RegisterCommand('pdprops', function()
    if not hasPermission() then
        lib.notify({description = 'Nemáš oprávnění!', type = 'error'})
        return
    end

    lib.registerContext({
        id = 'police_menu',
        title = 'Policejní Menu',
        options = {
            {
                title = 'Postavit Policejní Bariéru',
                description = 'Umístí policejní bariéru na zem',
                icon = 'triangle-exclamation',
                onSelect = function()
                    TriggerEvent('police:startPlacingObject', {object = 'prop_barrier_work05'})
                end
            },
            {
                title = 'Postavit Kužel',
                description = 'Umístí kužel na zem',
                icon = 'cone',
                onSelect = function()
                    TriggerEvent('police:startPlacingObject', {object = 'prop_roadcone02a'})
                end
            },
            {
                title = 'Postavit Pásy (spike strips)',
                description = 'Umístí pásy pro propíchnutí pneumatik',
                icon = 'road',
                onSelect = function()
                    TriggerEvent('police:startPlacingObject', {object = 'p_ld_stinger_s'})
                end
            }
        }
    })

    lib.showContext('police_menu')
end)

-- Klávesová zkratka
RegisterKeyMapping('pdprops', 'Policejní Menu', 'keyboard', 'F5')

-- Při připojení hráče
AddEventHandler('playerSpawned', function()
    Wait(2000)
    TriggerServerEvent('police:requestObjects')
end)