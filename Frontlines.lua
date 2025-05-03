local Workspace = findfirstchild(Game, "Workspace")

local TrackedModels = {} 
local ModelCounter = 0 

local function GenerateUniqueKey(model)
    ModelCounter = ModelCounter + 1
    return "sen_" .. tostring(ModelCounter)
end

local function GetBodyParts(model)
    if not model then return nil end
    local parts = {
        Head = findfirstchild(model, "TPVBodyVanillaHead"),
        RootPart = findfirstchild(model, "HumanoidRootPart"),
        TorsoFront = findfirstchild(model, "TPVBodyVanillaTorsoFront"),
        TorsoBack = findfirstchild(model, "TPVBodyVanillaTorsoBack"),
        ArmL = findfirstchild(model, "TPVBodyVanillaArmL"),
        ArmR = findfirstchild(model, "TPVBodyVanillaArmR"),
        LegL = findfirstchild(model, "TPVBodyVanillaLegL"),
        LegR = findfirstchild(model, "TPVBodyVanillaLegR"),

    }

    if parts.Head and parts.RootPart and parts.TorsoFront then
        return parts
    end
    warn("Missing essential parts in model:", getname(model))
    return nil
end

local function CreateModelData(model, parts, uniqueKey)

    local modelName = uniqueKey 
    local playerName = "Soldier" 

    local isFriendly = false
    local friendlyMarker = findfirstchild(model, "friendly_marker")
    if friendlyMarker then
        isFriendly = true
    end

    local data = {

        Username = playerName,
        Displayname = playerName .. " (" .. modelName .. ")", 
        Userid = 0, 
        Character = model,
        PrimaryPart = parts.RootPart,
        Humanoid = parts.Head, 
        Head = parts.Head,
        Torso = parts.TorsoFront,
        UpperTorso = parts.TorsoFront,
        LowerTorso = parts.TorsoBack,
        LeftArm = parts.ArmL,
        RightArm = parts.ArmR,
        LeftLeg = parts.LegL,
        RightLeg = parts.LegR,
        HumanoidRootPart = parts.RootPart,
        Health = 100,
        MaxHealth = 100,
        RigType = 1,
        BodyHeightScale = 1,
        Team = isFriendly,
        Whitelisted = false,
        Archenemies = false,
        Aimbot_Part = parts.TorsoFront,
        Aimbot_TP_Part = parts.RootPart,
        Triggerbot_Part = parts.TorsoFront,
    }

    return modelName, data
end

local function UpdateModels()
    if not Workspace then return end

    local currentModels = {}
    pcall(function() currentModels = getchildren(Workspace) end)

    local seenModels = {} 

    for _, instance in ipairs(currentModels) do
        local isSoldierModel = false
        pcall(function()
            if getclassname(instance) == "Model" and getname(instance) == "soldier_model" then
                isSoldierModel = true
            end
        end)

        if isSoldierModel then
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
                        --print("Added model", uniqueKey, "Friendly:", tostring(modelData.Team ~= nil)) 
                    else
                        --warn("Failed to add model", uniqueKey, "-", err)

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
             --print("Removed model", removalInfo.key)
         else
             warn("Failed to remove model", removalInfo.key, "-", err)
         end

         TrackedModels[removalInfo.model] = nil 
    end
end

print("Initializing...")
if not Workspace then
    warn("Could not find Workspace. ESP will not function.")
end

spawn(function()
    while wait(0.5) do
        pcall(UpdateModels) 
    end
end)

print("[Sen] FRONTLINES Support loaded successfully.")

