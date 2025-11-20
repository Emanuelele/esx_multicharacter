Server = {}
Server._index = Server

Server.oneSync = GetConvar("onesync", "off")
Server.slots = Config.Slots or 4
Server.prefix = Config.Prefix or "char"
Server.identifierType = ESX.GetConfig().Identifier or GetConvar("sv_lan", "") == "true" and "ip" or "license"

AddEventHandler("playerConnecting", function(_, _, deferrals)
   local source = source
   Server:OnConnecting(source, deferrals)
end)

RegisterNetEvent("esx_multicharacter:SetupCharacters", function()
    local source = source
    Multicharacter:SetupCharacters(source)
end)

RegisterNetEvent("esx_multicharacter:CharacterChosen", function(charid, isNew)
    local source = source
    Multicharacter:CharacterChosen(source, charid, isNew)
end)

AddEventHandler("lele_firstspawn:completedSetup", function(source, data)
    Multicharacter:RegistrationComplete(source, data)
end)

AddEventHandler("playerDropped", function()
    local source = source
    Multicharacter:PlayerDropped(source)
end)

RegisterNetEvent("esx_multicharacter:DeleteCharacter", function(charid)
    if not Config.CanDelete or type(charid) ~= "number" or string.len(charid) > 2 then
        return
    end
    local source = source
    Database:DeleteCharacter(source, charid)
end)

RegisterNetEvent("esx_multicharacter:relog", function(targer)
    local source = targer
    TriggerEvent("esx:playerLogout", source)
end)

ESX.RegisterCommand("relog", 'admin', function(xPlayer, args, showError)
    local targetId = tonumber(args.playerId) or xPlayer.source

    if GetPlayerName(targetId) then
        -- Esegui il relog del giocatore
        TriggerEvent("esx_multicharacter:relog", targetId)

    else
        showError("ID giocatore non valido.")
    end
end, true, { -- abilitato anche da console
    help = "Forza un giocatore a riloggare",
    arguments = {
        { name = 'playerId', help = 'ID del giocatore (opzionale)', type = 'number', optional = true }
    }
})
