local zoneCenter = vector3(1983.5, 3051.4, 47.2) -- souřadnice Yellow Jack baru
local zoneRadius = 50.0 -- jak velký okruh se má kontrolovat (můžeš snížit)

Citizen.CreateThread(function()
    while true do
        Wait(5000) -- každých 5 vteřin
        local peds = GetGamePool("CPed")
        for _, ped in pairs(peds) do
            if not IsPedAPlayer(ped) then
                local pedCoords = GetEntityCoords(ped)
                if #(pedCoords - zoneCenter) < zoneRadius then
                    DeleteEntity(ped)
                end
            end
        end
    end
end)
