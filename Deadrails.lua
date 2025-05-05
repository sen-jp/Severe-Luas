local Workspace = findfirstchild(Game, "Workspace")
local NightEnemiesFolder = findfirstchild(Workspace, "NightEnemies")
local LocalPlayer = getlocalplayer()

local TrackedModels = {}

if not Workspace then
    warn("Dead Rails Support: Workspace not found!")
    return
end

if not NightEnemiesFolder then
    warn("Dead Rails Support: NightEnemies folder not found in Workspace!")
    return
end

warn("Dead Rails Support: Initializing for NightEnemies...")

local function GetBodyParts(Model)
    return {
        Head = findfirstchild(Model, "Head"),
        Torso = findfirstchild(Model, "Torso"),
        HumanoidRootPart = findfirstchild(Model, "HumanoidRootPart"),
        LeftArm = findfirstchild(Model, "Left Arm"),
        RightArm = findfirstchild(Model, "Right Arm"),
        LeftLeg = findfirstchild(Model, "Left Leg"),
        RightLeg = findfirstchild(Model, "Right Leg"),
        Humanoid = findfirstchild(Model, "Humanoid")
    }
end

local function TeamCheck(Entity)
    return false
end

local function IsLocalPlayer(Model)
    if not LocalPlayer then return false end
    local playerCharacter = getcharacter(LocalPlayer)
    return playerCharacter == Model
end

local function EnemyData(Model, Parts)
    local modelName = "UnknownEnemy"
    pcall(function() modelName = getname(Model) end)

    local Data = {
        Username = modelName,
        Displayname = modelName,
        Userid = 0,
        Character = Model,
        PrimaryPart = Parts.HumanoidRootPart or Parts.Torso,
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
        Aimbot_TP_Part = Parts.HumanoidRootPart or Parts.Torso,
        Triggerbot_Part = Parts.Head,
        Health = 100,
        MaxHealth = Parts.Humanoid and getmaxhealth(Parts.Humanoid) or 100,
    }
    return tostring(Model), Data
end

local function scanInstance(instance)
    local instanceClassName = getclassname(instance)

    if instanceClassName == "Model" then
        if not IsLocalPlayer(instance) then
            local Key = tostring(instance)
            local Parts = GetBodyParts(instance)

            if Parts.Head and (Parts.HumanoidRootPart or Parts.Torso) then
                if not TrackedModels[Key] then
                    local ID, Data = EnemyData(instance, Parts)
                    if add_model_data(Data, ID) then
                        TrackedModels[ID] = instance
                    end
                end
                return true
            end
        end
    elseif instanceClassName == "Folder" then
        local children = getchildren(instance)
        local folderSeen = false
        for _, child in ipairs(children) do
             if scanInstance(child) then
                 folderSeen = true
             end
        end
        return folderSeen
    end
    return false
end


local function Update()
    local Seen = {}

    local children = getchildren(NightEnemiesFolder)
    for _, item in ipairs(children) do
        if scanInstance(item) then
           if getclassname(item) == "Model" then
               local key = tostring(item)
               if TrackedModels[key] then
                   Seen[key] = true
               end
           else
                local descendants = getdescendants(item)
                for _, desc in ipairs(descendants) do
                    if getclassname(desc) == "Model" then
                         local key = tostring(desc)
                         if TrackedModels[key] then
                             Seen[key] = true
                         end
                    end
                end
           end
        end
    end

    -- Remove models that are no longer present or valid
    for Key, Model in pairs(TrackedModels) do
        local parent = getparent(Model)
        local primaryPart = findfirstchild(Model, "HumanoidRootPart") or findfirstchild(Model, "Torso")

        -- Remove if not seen in the current scan, parent is nil, or primary part is gone
        if not Seen[Key] or not parent or not primaryPart then
            remove_model_data(Key) -- Use Severe's function
            TrackedModels[Key] = nil
            -- print("Dead Rails: Removed", Key) -- Optional debug print
        else
            -- Optionally update health here if needed
            local humanoid = findfirstchild(Model, "Humanoid")
            if humanoid then
                 local currentHealth = gethealth(humanoid)
            end
        end
    end
end

-- Initial scan
Update()

-- Continuous update loop (using Severe's task scheduler if available, otherwise a simple loop)
-- If Severe has a built-in way to run update loops (e.g., task.spawn, RunService connection), use that.
-- Otherwise, a basic spawn + wait loop:
spawn(function()
    while true do
        Update()
        wait(1) -- Adjust update frequency as needed
    end
end)

warn("Dead Rails Support: Running.")
