local Workspace = findfirstchild(Game, "Workspace")
local MapFolder = findfirstchild(Workspace, "MapFolder")
local PlayersFolder = findfirstchild(MapFolder, "Players")

local TrackedModels = {}
local ModelCounter = 0
local LocalPlayerName = nil
local localPlayerTeam = nil

local function getPlayerTeam(model)
    if not model then return nil end
    local permanentTeamValueInstance = findfirstchild(model, "PermanentTeam")
    if permanentTeamValueInstance then
        local success, teamValue = pcall(function()
            return getvalue(permanentTeamValueInstance)
        end)
        if success then
            return teamValue
        end
    end
    return nil
end

pcall(function()
    local localPlayerInstance = getlocalplayer()
    if localPlayerInstance then
        LocalPlayerName = getname(localPlayerInstance)
        print("Found local player:", LocalPlayerName)
        if PlayersFolder and LocalPlayerName then
            local localPlayerModel = findfirstchild(PlayersFolder, LocalPlayerName)
            if localPlayerModel then
                localPlayerTeam = getPlayerTeam(localPlayerModel)
                if localPlayerTeam then
                    print("Local player team is:", tostring(localPlayerTeam))
                else
                    warn("Could not determine local player's team from model:", LocalPlayerName)
                end
            else
                warn("Local player model not found in PlayersFolder for team check:", LocalPlayerName)
            end
        end
    else
        warn("Could not get local player instance.")
    end
end)


local function GenerateUniqueKey(model)
    ModelCounter = ModelCounter + 1
    local name = "unknown"
    pcall(function() name = getname(model) end)
    return "rp_" .. name .. "_" .. tostring(ModelCounter)
end

local function GetBodyParts(model)
    if not model then return nil end
    local parts = {
        Head = findfirstchild(model, "Head"),
        RootPart = findfirstchild(model, "HumanoidRootPart"),
        UpperTorso = findfirstchild(model, "UpperTorso"),
        LeftUpperArm = findfirstchild(model, "LeftUpperArm"),
        LeftLowerArm = findfirstchild(model, "LeftLowerArm"),
        LeftHand = findfirstchild(model, "LeftHand"),
        RightUpperArm = findfirstchild(model, "RightUpperArm"),
        RightLowerArm = findfirstchild(model, "RightLowerArm"),
        RightHand = findfirstchild(model, "RightHand"),
        LeftUpperLeg = findfirstchild(model, "LeftUpperLeg"),
        LeftLowerLeg = findfirstchild(model, "LeftLowerLeg"),
        LeftFoot = findfirstchild(model, "LeftFoot"),
        RightUpperLeg = findfirstchild(model, "RightUpperLeg"),
        RightLowerLeg = findfirstchild(model, "RightLowerLeg"),
        RightFoot = findfirstchild(model, "RightFoot")
    }

    if parts.Head and parts.RootPart and parts.UpperTorso then
        parts.Torso = parts.UpperTorso
        parts.LeftArm = parts.LeftUpperArm or parts.LeftHand
        parts.RightArm = parts.RightUpperArm or parts.RightHand
        parts.LeftLeg = parts.LeftUpperLeg or parts.LeftFoot
        parts.RightLeg = parts.RightUpperLeg or parts.RightFoot
        return parts
    end
    
    local modelName = getname(model)
    if modelName ~= "Sand Wall" or modelName ~= "Combat Turret" then
        --warn("Missing essential parts in model:", modelName)
    end
    return nil
end

local function CreateModelData(model, parts, uniqueKey)
    local modelName = "Unknown Player"
    pcall(function() modelName = getname(model) end)
    local playerName = modelName

    local isFriendly = false

    local data = {
        Username = playerName,
        Displayname = playerName,
        Userid = 0,
        Character = model,
        PrimaryPart = parts.RootPart,
        Humanoid = parts.Head,
        Head = parts.Head,
        Torso = parts.Torso,
        UpperTorso = parts.UpperTorso,
        LowerTorso = parts.UpperTorso,
        LeftArm = parts.LeftArm,
        RightArm = parts.RightArm,
        LeftLeg = parts.LeftLeg,
        RightLeg = parts.RightLeg,
        HumanoidRootPart = parts.RootPart,
        Health = 100,
        MaxHealth = 100,
        RigType = 1,
        BodyHeightScale = 1,
        Team = isFriendly,
        Whitelisted = false,
        Archenemies = false,
        Aimbot_Part = parts.Head,
        Aimbot_TP_Part = parts.Head,
        Triggerbot_Part = parts.Head,
    }

    return uniqueKey, data
end

local function UpdateModels()
    if not PlayersFolder then return end

    if not LocalPlayerName then
        pcall(function()
            local localPlayerInstance = getlocalplayer()
            if localPlayerInstance then
                LocalPlayerName = getname(localPlayerInstance)
                if PlayersFolder and LocalPlayerName then
                    local localPlayerModel = findfirstchild(PlayersFolder, LocalPlayerName)
                    if localPlayerModel then
                        localPlayerTeam = getPlayerTeam(localPlayerModel)
                        if localPlayerTeam then
                             --print("Local player team is:", tostring(localPlayerTeam))
                        else
                            warn("Could not get local player's team for:", LocalPlayerName)
                        end
                    end
                end
            end
        end)
    elseif LocalPlayerName and not localPlayerTeam then
        if PlayersFolder then
            local localPlayerModel = findfirstchild(PlayersFolder, LocalPlayerName)
            if localPlayerModel then
                localPlayerTeam = getPlayerTeam(localPlayerModel)
                if localPlayerTeam then
                    print("[Refresh]: Local player team is:", tostring(localPlayerTeam))
                else
                    warn("[Refresh]: Failed to get local player team for:", LocalPlayerName)
                end
            end
        end
    end

    local currentModels = {}
    pcall(function() currentModels = getchildren(PlayersFolder) end)

    local seenModels = {}

    for _, instance in ipairs(currentModels) do
        local isModelInstance = false
        local instanceName = nil
        pcall(function()
            if getclassname(instance) == "Model" then
                isModelInstance = true
                instanceName = getname(instance)
            end
        end)

        if not isModelInstance then
            continue
        end

        local cloneTag = findfirstchild(instance, "CloneTag")
        if cloneTag then
            continue 
        end

        if LocalPlayerName and instanceName == LocalPlayerName then
            continue
        end

        if localPlayerTeam then
            local currentInstanceTeam = getPlayerTeam(instance)
            if currentInstanceTeam and currentInstanceTeam == localPlayerTeam then
                continue
            end
        end

        local model = instance
        seenModels[model] = true

        if not TrackedModels[model] then
            local parts = GetBodyParts(model)
            if parts then
                local uniqueKey = GenerateUniqueKey(model)
                local _, modelData = CreateModelData(model, parts, uniqueKey)

                local success, err = pcall(add_model_data, modelData, uniqueKey)
                if success then
                    TrackedModels[model] = uniqueKey
                else
                    ModelCounter = ModelCounter - 1
                end
            end
        end
    end

    local modelsToRemove = {}
    for modelInstance, uniqueKey in pairs(TrackedModels) do
        if not seenModels[modelInstance] then
            table.insert(modelsToRemove, {model = modelInstance, key = uniqueKey})
        end
    end

    for _, removalInfo in ipairs(modelsToRemove) do
         local success, err = pcall(remove_model_data, removalInfo.key)
         if success then
         else
             warn("Failed to remove model", removalInfo.key, "-", err)
         end
         TrackedModels[removalInfo.model] = nil
    end
end

print("Initializing Rush Point Support...")
if not Workspace then
    warn("Could not find Workspace.")
elseif not MapFolder then
    warn("Could not find MapFolder in Workspace.")
elseif not PlayersFolder then
    warn("Could not find Players folder in MapFolder. ESP will not function.")
end

spawn(function()
    while wait(0.5) do
        local success, err = pcall(UpdateModels)
        if not success then
            warn("Error in 'UpdateModels':" .. err .. " | @ me on discord with a screenshot.")
        end
    end
end)

local function bHopLoop()
    local localPlayer = getlocalplayer()
    local spaceKeyValue = "Space"
    local jumpForce = 50 
    local pressDelay = 0.05 
    local checkInterval = 0.03 

    local keys, keysSuccess, spaceHeld
    local character, primaryPart, currentVelocity, currentVelocitySuccess

    while wait(checkInterval) do
        keysSuccess, keys = pcall(getpressedkeys)

        if keysSuccess and type(keys) == "table" then
            spaceHeld = false
            for _, keyNameInLoop in ipairs(keys) do
                if keyNameInLoop == spaceKeyValue then
                    spaceHeld = true
                    break 
                end
            end

            if spaceHeld then
                if localPlayer then
                    character = getcharacter(localPlayer)
                    if character then
                        primaryPart = getprimarypart(character)
                        if primaryPart then
                            currentVelocitySuccess, currentVelocity = pcall(getvelocity, primaryPart)
                            if currentVelocitySuccess and type(currentVelocity) == "table" and currentVelocity.x ~= nil then
                                pcall(setvelocity, primaryPart, {currentVelocity.x, jumpForce, currentVelocity.z})
                                wait(pressDelay) 
                            end
                        end
                    end
                end
            end
        end
    end
end

spawn(bHopLoop)

print("[Sen] RUSH POINT Support loaded successfully.")
