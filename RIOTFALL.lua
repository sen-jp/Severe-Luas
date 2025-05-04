local Workspace = findfirstchild(Game, "Workspace")
local CharacterMeshes = Workspace and findfirstchild(Workspace, "CharacterMeshes")
local LocalPlayer = getlocalplayer()
local LocalPlayerName = nil
local LocalPlayerModel = nil

if LocalPlayer then
    pcall(function()
        LocalPlayerName = getname(LocalPlayer)
        LocalPlayerModel = findfirstchild(Workspace, LocalPlayerName)
        if not LocalPlayerModel then
             if CharacterMeshes then
                 LocalPlayerModel = findfirstchild(CharacterMeshes, LocalPlayerName)
             end
        end
    end)
end

local TrackedModels = {}
local ModelCounter = 0

local function GenerateUniqueKey(model)
    ModelCounter = ModelCounter + 1
    local name = "char"
    pcall(function() name = getname(model) end)
    return "riot_" .. name .. "_" .. tostring(ModelCounter)
end

local function GetBodyParts(model)
    if not model then return nil end

    local parts = {
        Head = findfirstchild(model, "head_only"),
        RootPart = findfirstchild(model, "RootPart"),
        TorsoProxy = findfirstchild(model, "pc_front") or findfirstchild(model, "shirt"),
        LeftArmProxy = findfirstchild(model, "pc_pouch_L") or findfirstchild(model, "shirt"),
        RightArmProxy = findfirstchild(model, "pc_pouch_R") or findfirstchild(model, "shirt"),
        LeftLegProxy = findfirstchild(model, "pants"),
        RightLegProxy = findfirstchild(model, "pants")
    }

    if parts.Head and parts.RootPart and parts.TorsoProxy then
        return parts
    end
    return nil
end

local function CreateModelData(model, parts, uniqueKey)
    local modelName = "UnknownCharacter"
    pcall(function() modelName = getname(model) end)
    local playerName = modelName

    local data = {
        Username = playerName,
        Displayname = playerName,
        Userid = 0,
        Character = model,
        PrimaryPart = parts.RootPart,
        Humanoid = parts.Head,
        Head = parts.Head,
        Torso = parts.TorsoProxy,
        UpperTorso = parts.TorsoProxy,
        LeftArm = parts.LeftArmProxy or parts.RootPart,
        RightArm = parts.RightArmProxy or parts.RootPart,
        LeftLeg = parts.LeftLegProxy or parts.RootPart,
        RightLeg = parts.RightLegProxy or parts.RootPart,
        HumanoidRootPart = parts.RootPart,
        Health = 100,
        MaxHealth = 100,
        RigType = 1,
        BodyHeightScale = 1,
        Team = nil,
        Whitelisted = false,
        Archenemies = false,
        Aimbot_Part = parts.Head,
        Aimbot_TP_Part = parts.Head,
        Triggerbot_Part = parts.Head or parts.TorsoProxy,
    }

    return uniqueKey, data
end

local function UpdateModels()
    if not CharacterMeshes then return end

    if not LocalPlayerModel and LocalPlayerName then
         pcall(function()
             LocalPlayerModel = findfirstchild(Workspace, LocalPlayerName)
             if not LocalPlayerModel and CharacterMeshes then
                 LocalPlayerModel = findfirstchild(CharacterMeshes, LocalPlayerName)
             end
         end)
    end

    local currentInstances = {}
    pcall(function() currentInstances = getchildren(CharacterMeshes) end)

    local seenModels = {}

    for _, instance in ipairs(currentInstances) do
        local isModel = false
        pcall(function()
            if getclassname(instance) == "Model" then
                isModel = true
            end
        end)

        if isModel then
            if LocalPlayerModel and instance == LocalPlayerModel then
            else
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

print("Initializing RIOTFALL Support...")
if not Workspace then
    warn("RIOTFALL: Could not find Workspace.")
elseif not CharacterMeshes then
    warn("RIOTFALL: Could not find CharacterMeshes folder in Workspace.")
end
if not LocalPlayer then
    warn("RIOTFALL: Could not find Local Player.")
end

spawn(function()
    while wait(0.5) do
        local success, err = pcall(UpdateModels)
        if not success then
            warn("Error in RIOTFALL UpdateModels:", err)
        end
    end
end)

print("[Sen] RIOTFALL Support loaded successfully.")