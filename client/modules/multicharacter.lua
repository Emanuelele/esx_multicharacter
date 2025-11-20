---@diagnostic disable: duplicate-set-field
Multicharacter = {}
Multicharacter._index = Multicharacter
Multicharacter.canRelog = true
Multicharacter.Characters = {}
Multicharacter.hidePlayers = false
Multicharacter.characterPeds = {}

function Multicharacter:SetupCamera()
    if not self.cam then
        self.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamActive(self.cam, true)
        RenderScriptCams(true, false, 1, true, true)
    end
    SetTimecycleModifier('TREVOR')
    SetTimecycleModifierStrength(1.0)
    SetCamCoord(self.cam, Config.Camera.position.x, Config.Camera.position.y, Config.Camera.position.z)
    PointCamAtCoord(self.cam, Config.Camera.pointAt.x, Config.Camera.pointAt.y, Config.Camera.pointAt.z)
    SetCamFov(self.cam, Config.Camera.fov)
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

function Multicharacter:DeleteAllCharacterPeds()
    self:StopPedClickDetection()
    
    for _, ped in pairs(self.characterPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    self.characterPeds = {}
end

function Multicharacter:SpawnAllCharacterPeds()
    self:DeleteAllCharacterPeds()
    
    for index, character in pairs(self.Characters) do
        local pedConfig = Config.CharacterPeds[index]
        if not pedConfig then
            print("^1[ERROR] Configurazione mancante per il ped slot " .. index .. "^0")
            goto continue
        end
        
        local skin = character.skin
        if type(skin) == "string" then
            skin = json.decode(skin)
        end
        
        local model = skin and skin.model or (character.sex == "Maschio" and `mp_m_freemode_01` or `mp_f_freemode_01`)
        
        local ped = CreatePed(4, model, pedConfig.position.x, pedConfig.position.y, pedConfig.position.z, pedConfig.heading, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetEntityInvincible(ped, true)
        
        if pedConfig.collision then
            SetEntityCollision(ped, true, true)
        else
            SetEntityCollision(ped, false, false)
        end
        
        if pedConfig.freeze then
            FreezeEntityPosition(ped, true)
        end
        
        if skin then
            exports["fivem-appearance"]:setPedAppearance(ped, skin)
        end
        
        if pedConfig.animation then
            local animDict = pedConfig.animation.dict
            local animName = pedConfig.animation.name
            RequestAnimDict(animDict)
            while not HasAnimDictLoaded(animDict) do
                Citizen.Wait(0)
            end
            TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
        
        self.characterPeds[index] = ped
        
        ::continue::
    end
    
    Citizen.Wait(100)
    self:StartPedClickDetection()
end

function Multicharacter:StartPedClickDetection()
    if self.clickThread then return end
    
    self.clickThread = true
    
    Citizen.CreateThread(function()
        while self.clickThread and next(self.characterPeds) do
            if IsControlJustPressed(0, 24) then
                local hit, entity = self:GetCameraHitEntity()
                
                if hit and entity and DoesEntityExist(entity) then
                    for index, ped in pairs(self.characterPeds) do
                        if entity == ped then
                            Multicharacter:SetupCharacter(index)
                            Menu:CharacterOptions()
                            break
                        end
                    end
                end
            end
            
            Citizen.Wait(0)
        end
        
        self.clickThread = false
    end)
end

function Multicharacter:GetCameraHitEntity()
    local camCoord = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local camForward = self:RotationToDirection(camRot)
    local destination = vector3(
        camCoord.x + camForward.x * 100.0,
        camCoord.y + camForward.y * 100.0,
        camCoord.z + camForward.z * 100.0
    )
    
    local rayHandle = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        destination.x, destination.y, destination.z,
        -1,
        PlayerPedId(),
        0
    )
    
    local _, hit, _, _, entity = GetShapeTestResult(rayHandle)
    
    return hit == 1, entity
end

function Multicharacter:RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    
    return vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
end

function Multicharacter:StopPedClickDetection()
    self.clickThread = false
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
    SetEntityAlpha(self.playerPed, 0, false)
    self:HideHud(true)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    TriggerEvent("esx:loadingScreenOff")
    SetTimeout(200, function()
        TriggerServerEvent("esx_multicharacter:SetupCharacters")
    end)
end

function Multicharacter:PrepForUI()
    for index, ped in pairs(self.characterPeds) do
        if index == self.spawned then
            SetPedAoBlobRendering(ped, true)
            SetEntityAlpha(ped, 255, false)
        else
            SetEntityAlpha(ped, 150, false)
        end
    end
end

function Multicharacter:CloseUI()
    SendNUIMessage({
        action = "closeui",
    })
end

function Multicharacter:SetupCharacter(index)
    local character = self.Characters[index]
    self.tempIndex = index
    self.spawned = index
    
    self:PrepForUI()
    
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
        SetEntityCoords(PlayerPedId())
        self:SpawnAllCharacterPeds()
        self:SetupCamera()
        DoScreenFadeIn(600)
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
    end)
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
    self:DeleteAllCharacterPeds()
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