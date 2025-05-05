local Workspace = findfirstchild(Game, "Workspace")
local LocalPlayer = getlocalplayer()
local TrackedModels = {}

if not Workspace then
    warn("AutoIndex: Workspace not found!")
    return
end

if not LocalPlayer then
    warn("AutoIndex: LocalPlayer not found!")
end

warn("AutoIndex: Initializing universal model scanning...")

local function GetBodyParts(Model)
    return {
        Head = findfirstchild(Model, "Head"),
        Torso = findfirstchild(Model, "Torso") or findfirstchild(Model, "UpperTorso"),
        HumanoidRootPart = findfirstchild(Model, "HumanoidRootPart") or findfirstchild(Model, "RootPart"),
        LeftArm = findfirstchild(Model, "Left Arm") or findfirstchild(Model, "LeftUpperArm"),
        RightArm = findfirstchild(Model, "Right Arm") or findfirstchild(Model, "RightUpperArm"),
        LeftLeg = findfirstchild(Model, "Left Leg") or findfirstchild(Model, "LeftUpperLeg"),
        RightLeg = findfirstchild(Model, "Right Leg") or findfirstchild(Model, "RightUpperLeg"),
        Humanoid = findfirstchild(Model, "Humanoid")
    }
end

local function IsLocalPlayer(Model)
    if not LocalPlayer then return false end
    local playerCharacter = getcharacter(LocalPlayer)
    return playerCharacter == Model
end

local function ModelData(Model, Parts)
    local modelName = "UnknownCharacter"
    pcall(function() modelName = getname(Model) end)

    local primaryPart = Parts.HumanoidRootPart or Parts.Torso

    local Data = {
        Username = modelName,
        Displayname = modelName,
        Userid = 0,
        Character = Model,
        PrimaryPart = primaryPart,
        Humanoid = Parts.Humanoid,
        Head = Parts.Head,
        Torso = Parts.Torso,
        LeftArm = Parts.LeftArm,
        LeftLeg = Parts.LeftLeg,
        RightArm = Parts.RightArm,
        RightLeg = Parts.RightLeg,
        BodyHeightScale = 1,
        RigType = 0,
        Whitelisted = false,
        Archenemies = false,
        Aimbot_Part = Parts.Head,
        Aimbot_TP_Part = primaryPart,
        Triggerbot_Part = Parts.Head,
        Health = 100,
        MaxHealth = Parts.Humanoid and getmaxhealth(Parts.Humanoid) or 100,
    }
    return tostring(Model), Data
end

local function scanInstance(instance, SeenTable)
    local instanceClassName = getclassname(instance)

    if instanceClassName == "Model" then
        if not IsLocalPlayer(instance) then
            local Key = tostring(instance)
            local Parts = GetBodyParts(instance)

            if Parts.Head and (Parts.HumanoidRootPart or Parts.Torso) then
                if not TrackedModels[Key] then
                    local ID, Data = ModelData(instance, Parts)
                    if add_model_data(Data, ID) then
                        TrackedModels[ID] = instance
                    end
                end
                SeenTable[Key] = true
                return true
            end
        end
    else
        if instanceClassName == "Folder" or instanceClassName == "Model" then
            local children = getchildren(instance)
            local foundValidChild = false
            for _, child in ipairs(children) do
                 if scanInstance(child, SeenTable) then
                     foundValidChild = true
                 end
            end
            return foundValidChild
        end
    end
    return false
end


local function Update()
    local Seen = {}

    local workspaceChildren = getchildren(Workspace)
    for _, item in ipairs(workspaceChildren) do
        scanInstance(item, Seen)
    end

    for Key, Model in pairs(TrackedModels) do
        local parent = getparent(Model)
        local primaryPart = findfirstchild(Model, "HumanoidRootPart") or findfirstchild(Model, "Torso") or findfirstchild(Model, "UpperTorso") or findfirstchild(Model, "RootPart")

        if not Seen[Key] or not parent or not primaryPart then
            remove_model_data(Key)
            TrackedModels[Key] = nil
        else
            local humanoid = findfirstchild(Model, "Humanoid")
            if humanoid then
                 local currentHealth = gethealth(humanoid)
            end
        end
    end
end

Update()

spawn(function()
    while true do
        Update()
        wait(2)
    end
end)

warn("AutoIndex: Running.")
