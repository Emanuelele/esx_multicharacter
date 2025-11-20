---@diagnostic disable: duplicate-set-field
Multicharacter = {}
Multicharacter._index = Multicharacter
Multicharacter.canRelog = true
Multicharacter.Characters = {}
Multicharacter.hidePlayers = false

function Multicharacter:SetupCamera()
    self.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamActive(self.cam, true)
    RenderScriptCams(true, false, 1, true, true)

    -- Ottieni le coordinate del ped e calcola l'offset per posizionare la cam frontalmente
    local pedCoords = GetEntityCoords(self.playerPed)
    local forwardOffset = GetOffsetFromEntityInWorldCoords(self.playerPed, 0.5, 1.6, 0.6) -- Altezza busto (y per distanza, z per altezza)

    -- Imposta la posizione della camera e orientala verso il ped
    SetCamCoord(self.cam, forwardOffset.x, forwardOffset.y, forwardOffset.z - 1.0)
    PointCamAtCoord(self.cam, pedCoords.x, pedCoords.y, pedCoords.z - 0.5) -- Altezza busto del ped
    SetCamFov(self.cam, 38.0)
end

function Multicharacter:SetupLight()
    Citizen.CreateThread(function()
        SetTimecycleModifier("MP_race_finish")
        SetTimecycleModifierStrength(1.0)
        while not ESX.PlayerLoaded do
            -- Ottieni l'heading del ped in radianti
            local heading = math.rad(GetEntityHeading(self.playerPed))

            -- Calcola l'offset per spostare la luce a sinistra del ped
            local offsetXLeft = math.cos(heading) * -1.0 -- Sinistra rispetto all'heading
            local offsetYLeft = math.sin(heading) * -1.0
            local offsetZ = 1.0                          -- Altezza sopra il ped

            -- Posizione della luce a sinistra
            local lightXLeft = self.spawnCoords.x + offsetXLeft
            local lightYLeft = self.spawnCoords.y + offsetYLeft
            local lightZLeft = self.spawnCoords.z + offsetZ

            -- Direzione della luce a sinistra (verso il ped)
            local dirXLeft = -offsetXLeft
            local dirYLeft = -offsetYLeft
            local dirZLeft = -0.5 -- Leggermente inclinata verso il basso

            -- Disegna la luce a sinistra
            DrawSpotLight(lightXLeft, lightYLeft, lightZLeft, dirXLeft, dirYLeft, dirZLeft, 250, 180, 50, 15.0, 10.0, 6.0,
                22.0, 0.5)

            -- Calcola l'offset per spostare la luce a destra del ped
            local offsetXRight = math.cos(heading) * 1.0 -- Destra rispetto all'heading
            local offsetYRight = math.sin(heading) * 1.0

            -- Posizione della luce a destra
            local lightXRight = self.spawnCoords.x + offsetXRight
            local lightYRight = self.spawnCoords.y + offsetYRight
            local lightZRight = self.spawnCoords.z + offsetZ

            -- Direzione della luce a destra (verso il ped)
            local dirXRight = -offsetXRight
            local dirYRight = -offsetYRight
            local dirZRight = -0.8 -- Leggermente inclinata verso il basso

            -- Disegna la luce a destra
            DrawSpotLight(lightXRight, lightYRight, lightZRight, dirXRight, dirYRight, dirZRight, 0, 61, 71, 15.0, 10.0,
                6.0, 22.0, 0.5)

            Citizen.Wait(0)
        end
        ClearTimecycleModifier()
    end)
end

function Multicharacter:AwaitFadeIn()
    while IsScreenFadingIn() do
        Wait(200)
    end
end

function Multicharacter:AwaitFadeOut()
    while IsScreenFadingOut() do
        Wait(200)
    end
end

function Multicharacter:DestoryCamera()
    if self.cam then
        SetCamActive(self.cam, false)
        RenderScriptCams(false, false, 0, true, true)
        self.cam = nil
    end
end

local HiddenCompents = {}

local function HideComponents(hide)
    local components = { 11, 12, 21 }
    for i = 1, #components do
        if hide then
            local size = GetHudComponentSize(components[i])
            if size.x > 0 or size.y > 0 then
                HiddenCompents[components[i]] = size
                SetHudComponentSize(components[i], 0.0, 0.0)
            end
        else
            if HiddenCompents[components[i]] then
                local size = HiddenCompents[components[i]]
                SetHudComponentSize(components[i], size.x, size.z)
                HiddenCompents[components[i]] = nil
            end
        end
    end
    DisplayRadar(false)
end

function Multicharacter:HideHud(hide)
    self.hidePlayers = true

    MumbleSetVolumeOverride(ESX.PlayerId, 0.0)
    HideComponents(hide)
end

function Multicharacter:SetupCharacters()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}

    self.spawned = false

    self.playerPed = PlayerPedId()
    self.spawnCoords = Config.Spawn[ESX.Math.Random(1, #Config.Spawn)]
    SetEntityCoords(self.playerPed, self.spawnCoords.x, self.spawnCoords.y, self.spawnCoords.z, false, false, false, true)
    Citizen.Wait(10)
    local interior = GetInteriorAtCoords(self.spawnCoords.x, self.spawnCoords.y, self.spawnCoords.z)
    if IsValidInterior(interior) then
        LoadInterior(interior)
    end
    SetPlayerControl(ESX.PlayerId, false, 0)
    SetEntityHeading(self.playerPed, 280.0)
    self:SetupCamera()
    self:SetupLight()
    self:HideHud(true)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    TriggerEvent("esx:loadingScreenOff")
    SetTimeout(200, function()
        TriggerServerEvent("esx_multicharacter:SetupCharacters")
        print("SetupCharacters called")
    end)
end

function Multicharacter:GetSkin()
    local character = self.Characters[self.tempIndex]
    local skin = character and character.skin or Config.Default
    if not character.model then
        if character.sex == TranslateCap("female") then
            skin.sex = 1
        else
            skin.sex = 0
        end
    end
    return skin
end

function Multicharacter:SpawnTempPed()
    self.canRelog = false
    local skin = self:GetSkin()
    print(skin, json.encode(skin))
    ESX.SpawnPlayer(skin, self.spawnCoords, function()
        DoScreenFadeIn(600)
        self.playerPed = PlayerPedId()
        SetEntityHeading(self.playerPed, 280.0)

        local animDict = 'amb@world_human_stand_impatient@male@no_sign@idle_a'
        local animName = 'idle_b'
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(0)
        end
        TaskPlayAnim(self.playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        exports["fivem-appearance"]:setPlayerAppearance(skin)
    end)
end

function Multicharacter:ChangeExistingPed()
    local newCharacter = self.Characters[self.tempIndex]
    local spawnedCharacter = self.Characters[self.spawned]

    if spawnedCharacter and spawnedCharacter.model then
        local model = ESX.Streaming.RequestModel(newCharacter.model)
        if model then
            SetPlayerModel(ESX.playerId, newCharacter.model)
            SetModelAsNoLongerNeeded(newCharacter.model)
        end
    end

    exports["fivem-appearance"]:setPlayerAppearance(newCharacter.skin)
end

function Multicharacter:PrepForUI()
    FreezeEntityPosition(self.playerPed, true)
    SetPedAoBlobRendering(self.playerPed, true)
    SetEntityAlpha(self.playerPed, 255, false)
end

function Multicharacter:CloseUI()
    SendNUIMessage({
        action = "closeui",
    })
end

function Multicharacter:SetupCharacter(index)
    local character = self.Characters[index]
    self.tempIndex = index

    if not self.spawned then
        print("temp ped?")
        self:SpawnTempPed()
    elseif character and character.skin then
        self:ChangeExistingPed()
    end

    self.spawned = index
    self.playerPed = PlayerPedId()
    self:PrepForUI()
    print("openui", character, json.encode(character))
    SendNUIMessage({
        action = "openui",
        character = character,
    })
end

function Multicharacter:SetupUI(characters, slots)
    DoScreenFadeOut(0)
    self.Characters = characters
    self.slots = slots

    local Character = next(self.Characters)
    if not Character then
        local result = lib.callback.await("lele_firstspawn:initData", false, true)
        if result then
            self.canRelog = false

            ESX.SpawnPlayer(Config.Default, self.spawnCoords, function()
                --DoScreenFadeIn(400)
                --self:AwaitFadeIn()

                self.playerPed = PlayerPedId()
                SetPedAoBlobRendering(self.playerPed, false)
                SetEntityAlpha(self.playerPed, 0, false)

                TriggerServerEvent("esx_multicharacter:CharacterChosen", 1, true)
                DisplayRadar(false)
                exports["peakville_hud"]:SetHudsStatus(false)
                exports["peakville_chat"]:SetChatActive(false)
                exports["ox_inventory"]:setLogoVisibility(false)
                exports["peakville_pausemenu"]:DisableMenus(true)
            end)
        end
    else
        Menu:SelectCharacter()
    end
end

function Multicharacter:LoadSkinCreator()
    local interior = GetInteriorAtCoords(-788.1300, 5379.4722, 28.5728)
    if IsValidInterior(interior) then
        LoadInterior(interior)
    end
    
    local spawncoords = vec3(-788.1300, 5379.4722, 28.5728 - 0.8)
    SetEntityCoords(self.playerPed, spawncoords, false, false, false, true)
    SetEntityHeading(self.playerPed, 195.8)
    SetPedAoBlobRendering(self.playerPed, true)
    ResetEntityAlpha(self.playerPed)
    DoScreenFadeIn(1000)
    Citizen.CreateThread(function()
        while #(spawncoords - GetEntityCoords(PlayerPedId())) > 2 do
            Wait(1000)
            SetEntityCoords(PlayerPedId(), spawncoords, false, false, false, true)
        end
        ResetEntityAlpha(PlayerPedId())
        exports["fivem-appearance"]:setPlayerModel('mp_m_freemode_01')
        local config = {
            ped = false,
            headBlend = true,
            faceFeatures = true,
            headOverlays = true,
            components = true,
            props = true,
            allowExit = false,
            tattoos = true
        }

        exports["fivem-appearance"]:startPlayerCustomization(function(skin)
            TriggerServerEvent("lele_skinmanager:saveSkin", skin)
            exports["peakville_hud"]:SetHudsStatus(false)
            exports["peakville_chat"]:SetChatActive(false)
            exports["ox_inventory"]:setLogoVisibility(false)
            exports["peakville_pausemenu"]:DisableMenus(true)
            Multicharacter.finishedCreation = true
            Citizen.Wait(250)
            TriggerEvent("lele_firstspawn:init")
        end, config)

        --[[ exports["peakville_skincreator"]:OpenSkinCreator(function()
            exports["peakville_hud"]:SetHudsStatus(false)
            exports["peakville_chat"]:SetChatActive(false)
            exports["ox_inventory"]:setLogoVisibility(false)
            exports["peakville_pausemenu"]:DisableMenus(true)
            Multicharacter.finishedCreation = true
            TriggerServerEvent("lele_firstspawn:init")
        end) ]]
    end)
    --[[ end) ]]
end

function Multicharacter:SetDefaultSkin(playerData)
    ---@diagnostic disable-next-line: cast-local-type
    model = ESX.Streaming.RequestModel(`mp_m_freemode_01`)
    SetPlayerModel(ESX.playerId, model)
    SetModelAsNoLongerNeeded(model)
    self.playerPed = PlayerPedId()
    SetEntityAlpha(self.playerPed, 255, false)
    self:LoadSkinCreator()
end

function Multicharacter:Reset()
    self.Characters = {}
    self.tempIndex = nil
    self.playerPed = PlayerPedId()
    self.hidePlayers = false
    self.slots = nil

    SetTimeout(10000, function()
        self.canRelog = true
    end)
end

function Multicharacter:PlayerLoaded(playerData, isNew, skin)
    DoScreenFadeOut(1000)
    self:AwaitFadeOut()

    local esxSpawns = ESX.GetConfig().DefaultSpawns
    local spawn = esxSpawns[math.random(1, #esxSpawns)]

    if not isNew and playerData.coords then
        spawn = playerData.coords
    end

    if isNew or not skin or #skin == 1 then
        self.finishedCreation = false
        self:SetDefaultSkin(playerData)

        while not self.finishedCreation do
            Wait(200)
        end

        skin = exports["fivem-appearance"]:getPedAppearance(PlayerPedId())
        print(skin, json.encode(skin))
        DoScreenFadeOut(500)
        self:AwaitFadeOut()
    elseif not isNew then
        exports["fivem-appearance"]:setPlayerAppearance(skin or self.Characters[self.spawned].skin)
        NetworkEndTutorialSession()
    end

    self:DestoryCamera()
    if isNew then
        NetworkStartSoloTutorialSession()
        self:HideHud(false)
        SetPlayerControl(ESX.playerId, true, 0)

        self.playerPed = PlayerPedId()
        FreezeEntityPosition(self.playerPed, false)
        SetEntityCollision(self.playerPed, true, true)
        TriggerServerEvent("esx:onPlayerSpawn")
        TriggerEvent("esx:onPlayerSpawn")
        TriggerEvent("esx:restoreLoadout")
        self:Reset()
    else
        ESX.SpawnPlayer(skin, spawn, function()
            self:HideHud(false)
            SetPlayerControl(ESX.playerId, true, 0)

            self.playerPed = PlayerPedId()
            FreezeEntityPosition(self.playerPed, false)
            SetEntityCollision(self.playerPed, true, true)

            DoScreenFadeIn(1000)

            self:AwaitFadeIn()

            TriggerServerEvent("esx:onPlayerSpawn")
            TriggerEvent("esx:onPlayerSpawn")
            TriggerEvent("esx:restoreLoadout")
            self:Reset()
        end)
    end
    exports["peakville_hud"]:SetHudsStatus(true)
end

-- RegisterCommand('testhe', function()
--     SetEntityHeading(PlayerPedId(), 266.0)
-- end)
