local Workspace = findfirstchild(Game, "Workspace")
local MapFolder = findfirstchild(Workspace, "MapFolder")
local PlayersFolder = findfirstchild(MapFolder, "Players")

local TrackedModels = {}
local ModelCounter = 0

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
    if modelName ~= "Sand Wall" and modelName ~= "Combat Turret" then
        warn("Missing essential parts in model:", modelName)
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
        Aimbot_Part = parts.UpperTorso,
        Aimbot_TP_Part = parts.RootPart,
        Triggerbot_Part = parts.UpperTorso,
    }

    return uniqueKey, data
end

local function UpdateModels()
    if not PlayersFolder then return end

    local currentModels = {}
    pcall(function() currentModels = getchildren(PlayersFolder) end)

    local seenModels = {}

    for _, instance in ipairs(currentModels) do
        local isPlayerModel = false
        pcall(function()
            if getclassname(instance) == "Model" then
                isPlayerModel = true
            end
        end)

        if isPlayerModel then
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
                        -- print("Added Rush Point model", uniqueKey)
                    else
                        -- warn("Failed to add Rush Point model", uniqueKey, "-", err)
                        ModelCounter = ModelCounter - 1
                    end
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
             -- print("Removed Rush Point model", removalInfo.key)
         else
             warn("Failed to remove Rush Point model", removalInfo.key, "-", err)
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
            warn("Error in Rush Point UpdateModels:", err)
        end
    end
end)

print("[Sen] RUSH POINT Support loaded successfully.")