local Workspace = findfirstchild(Game, "Workspace")
local LocalPlayer = getlocalplayer()
local LocalPlayerName = nil
if LocalPlayer then
    pcall(function() LocalPlayerName = getname(LocalPlayer) end)
end

local TrackedModels = {}
local ModelCounter = 0

local function GenerateUniqueKey(model)
    ModelCounter = ModelCounter + 1
    local name = "player"
    pcall(function() name = getname(model) end)
    return "town_" .. name .. "_" .. tostring(ModelCounter)
end

local function GetBodyParts(model)
    if not model then return nil end
    local parts = {
        Head = findfirstchild(model, "Head"),
        Torso = findfirstchild(model, "Torso"),
        LeftArm = findfirstchild(model, "Left Arm"),
        RightArm = findfirstchild(model, "Right Arm"),
        LeftLeg = findfirstchild(model, "Left Leg"),
        RightLeg = findfirstchild(model, "Right Leg"),
        Humanoid = findfirstchildofclass(model, "Humanoid"),
        HumanoidRootPart = findfirstchild(model, "HumanoidRootPart")
    }

    if parts.Head and parts.HumanoidRootPart and parts.Humanoid and parts.Torso then
        return parts
    end
    return nil
end

local function CreateModelData(model, parts, uniqueKey)
    local modelName = "Unknown Player"
    pcall(function() modelName = getname(model) end)
    local playerName = modelName

    local health = 100
    local maxHealth = 100
    if parts.Humanoid then
        pcall(function() health = gethealth(parts.Humanoid) end)
        pcall(function() maxHealth = getmaxhealth(parts.Humanoid) end)
    end

    local data = {
        Username = playerName,
        Displayname = playerName,
        Userid = 0,
        Character = model,
        PrimaryPart = parts.HumanoidRootPart,
        Humanoid = parts.Humanoid,
        Head = parts.Head,
        Torso = parts.Torso,
        LeftArm = parts.LeftArm,
        RightArm = parts.RightArm,
        LeftLeg = parts.LeftLeg,
        RightLeg = parts.RightLeg,
        HumanoidRootPart = parts.HumanoidRootPart,
        Health = health,
        MaxHealth = maxHealth,
        RigType = 0,
        BodyHeightScale = 1,
        Team = nil,
        Whitelisted = false,
        Archenemies = false,
        Aimbot_Part = parts.Head,
        Aimbot_TP_Part = parts.HumanoidRootPart,
        Triggerbot_Part = parts.Head,
    }

    return uniqueKey, data
end

local function UpdateModels()
    if not Workspace then return end

    if not LocalPlayerName and LocalPlayer then
         pcall(function() LocalPlayerName = getname(LocalPlayer) end)
    end

    local currentInstances = {}
    pcall(function() currentInstances = getchildren(Workspace) end)

    local seenModels = {}

    for _, instance in ipairs(currentInstances) do
        local isModel = false
        local instanceName = nil
        pcall(function()
            if getclassname(instance) == "Model" then
                isModel = true
                instanceName = getname(instance)
            end
        end)

        if isModel then
            if not LocalPlayerName or instanceName ~= LocalPlayerName then
                local parts = GetBodyParts(instance)
                if parts then
                    local model = instance
                    seenModels[model] = true

                    if not TrackedModels[model] then
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
         TrackedModels[removalInfo.model] = nil
    end
end

print("Initializing Town Support...")
if not Workspace then
    warn("Town: Could not find Workspace.")
end
if not LocalPlayer then
    warn("Town: Could not find Local Player.")
end

spawn(function()
    while wait(0.5) do
        local success, err = pcall(UpdateModels)
        if not success then
            warn("Error in Town UpdateModels:", err)
        end
    end
end)

print("[Sen] Town Support loaded successfully.")