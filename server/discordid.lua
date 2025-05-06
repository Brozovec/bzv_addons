ESX = exports['es_extended']:getSharedObject()

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)

    deferrals.update("🔍 Waxanity: Kontrolujeme zda máte whitelist...")

    Wait(1000) 
    deferrals.done()
end)

RegisterNetEvent('waxanity:saveDiscordId')
AddEventHandler('waxanity:saveDiscordId', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    local identifiers = GetPlayerIdentifiers(src)
    local discordId = nil

    for _, id in pairs(identifiers) do
        if string.find(id, "discord:") then
            discordId = string.sub(id, 9)
            break
        end
    end

    if discordId then
        MySQL.update('UPDATE users SET discord_id = ? WHERE identifier = ?', {
            discordId,
            xPlayer.identifier
        }, function(rowsChanged)
            print(('[WAXANITY] Discord ID %s uložen pro hráče %s'):format(discordId, xPlayer.getName()))
        end)
    else
        print(('[WAXANITY] Nepodařilo se najít Discord ID pro hráče %s'):format(xPlayer.getName()))
    end
end)
