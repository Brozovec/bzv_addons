ESX = exports["es_extended"]:getSharedObject() 

local zones = {
    {
        name = "Tresspasing_1_Sandy_weed",
        coords = vec3(2348.0, 2569.5, 46.0),
        size = vec3(125.0, 164.5, 39.0),
        rotation = 0.0
    },
    {
        name = "Tresspasing_2_Vojenska_Zakladna", --První zona u sandy vjezd
        coords = vec3(-1590.14, 2795.61, 17.0),
        size = vec3(17.7, 4.1, 10.3),
        rotation = 42.0,
    },
    {
        name = "Tresspasing_3_Vojenska_Zakladna_V2", --První zona u dalnice v levlo Proste tady KOKOT
        coords = vec3(-2302.65, 3387.9, 31.0),
        size = vec3(8.0, 16.4, 10.0),
        rotation = 323.75,
    },
    {
        name = "Tresspasing_4_Human_Labs", -- Proste zona u humanlabs
        coords = vec3(3425.0896, 3761.5508, 30.6425),
        size = vec3(8.0, 16.4, 10.0),
        rotation = 26.3520,
    },
    {
        name = "Tresspasing_5_letsite_01", -- Proste zona vchod letiste 1
        coords = vec3(-984.1543, -2834.2031, 13.9645),
        size = vec3(8.0, 40.4, 10.0),
        rotation = 61.5534,
    },
    {
        name = "Tresspasing_6_letsite_02", -- Proste zona vchod prsotředek strana letsite 2
        coords = vec3(-1145.3558, -2727.6575, 13.9543),
        size = vec3(8.0, 40.4, 10.0),
        rotation = 235.1146,
    },
    {
        name = "Tresspasing_7_letsite_03", -- Proste zona vchod leva strana letsite 3
        coords = vec3(-1012.6595, -2412.7385, 13.9445),
        size = vec3(8.0, 40.4, 10.0),
        rotation = 157.0453,
    },
    {
        name = "Tresspasing_8_letsite_04", -- Proste zona vchod leva uplne zleva kolem LSC strana letsite 4
        coords = vec3(-989.7002, -2345.4844, 13.9249),
        size = vec3(8.0, 40.4, 10.0),
        rotation =  61.7460,
    },
}

local activeAlerts = {}
local ignoreJobs = { police = true, sheriff = true, sahp = true, ambulance = true, lsfd = true,} -- Přidat joby bababas
local playersInZone = {}

function onEnter(self, entity)
    local playerId = GetPlayerServerId(NetworkGetEntityOwner(entity))
    local player = ESX.GetPlayerData()
    --print('KOKOT') debug pro brozovce :)
    if not player or not player.job then
        return
    end

    local job = player.job.name
    local data = exports['cd_dispatch']:GetPlayerInfo() 
    local zoneName = self.name
    

    if ignoreJobs[job] then 
        return 
    end 

    if playersInZone[zoneName] and playersInZone[zoneName][playerId] then 
        return 
    end 

    if not playersInZone[zoneName] then
        playersInZone[zoneName] = {}
    end
    playersInZone[zoneName][playerId] = true
    
    if not activeAlerts[zoneName] then
        activeAlerts[zoneName] = true
        
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = {'police', 'sheriff', 'sahp', 'lsfd',},  -- Dodat joby ješte sem 
            coords = data.coords, 
            title = '10-17 - Trespassing',
            message = 'Podezřelá osoba na soukromém pozemku na ' .. data.street, 
            flash = 0,
            unique_id = data.unique_id,
            sound = 1,
            blip = {
                sprite = 161, 
                scale = 4, 
                colour = 3,
                flashes = false, 
                text = '10-17 - Trespassing',
                time = 30,
                radius = math.floor(math.max(self.size.x, self.size.y) *2), 
                alpha = 100 
            }
        })
    end
    
    lib.notify({
        title = 'Informace',
        description = 'Vstoupil jsi na soukromý pozemek',
        type = 'warning',
        duration = 2500,
    })
end

function onExit(self, entity)
    local playerId = GetPlayerServerId(NetworkGetEntityOwner(entity))
    local zoneName = self.name
    
    if playersInZone[zoneName] then
        playersInZone[zoneName][playerId] = nil
        
        if next(playersInZone[zoneName]) == nil then
            activeAlerts[zoneName] = nil
        end
    end
end

for _, zone in pairs(zones) do
    lib.zones.box({
        name = zone.name,
        coords = zone.coords,
        size = zone.size,
        rotation = zone.rotation,
        onEnter = onEnter,
        onExit = onExit,
        debug = false,

    })
end
