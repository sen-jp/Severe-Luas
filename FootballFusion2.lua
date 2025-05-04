local LocalPlayer = getlocalplayer()
local jumpBoost = 0.3
local spacePressedLastFrame = false
local lastBoostTime = 0
local cooldownDuration = 3
local showCooldownText = true

local cooldownText = nil
if showCooldownText then
    local success, resultX, resultY = pcall(getscreendimensions)
    local screenWidth, screenHeight

    if success and type(resultX) == "number" and type(resultY) == "number" then
        screenWidth = resultX
        screenHeight = resultY
    else
        screenWidth = 800
        screenHeight = 600
    end

    cooldownText = Drawing.new("Text")
    cooldownText.Visible = true
    cooldownText.Color = {255, 255, 255}
    cooldownText.Size = 18
    cooldownText.Outline = true
    cooldownText.OutlineColor = {0, 0, 0}
    cooldownText.Center = true
    cooldownText.Position = {screenWidth / 2, screenHeight - 50}
    cooldownText.Text = "Jump Boost: Ready"
end

local function keybindloop()
    while true do
        local currentTime = time()
        local currentpressedkeys = getpressedkeys()
        local spaceCurrentlyPressed = false

        if currentpressedkeys and isrbxactive() then
            for _, key in ipairs(currentpressedkeys) do
                if key == "Space" then
                    spaceCurrentlyPressed = true
                    break
                end
            end

            if spaceCurrentlyPressed and not spacePressedLastFrame then
                if currentTime - lastBoostTime >= cooldownDuration then
                    local char = getcharacter(LocalPlayer)
                    if char then
                        local hrp = findfirstchild(char, "HumanoidRootPart")
                        local humanoid = findfirstchild(char, "Humanoid")
                        if hrp and humanoid and gethealth(humanoid) > 0 then
                            local currentvelocity = getvelocity(hrp)
                            setvelocity(hrp, {currentvelocity.x, currentvelocity.y + jumpBoost, currentvelocity.z})
                            lastBoostTime = currentTime
                        end
                    end
                end
            end
        end

        if showCooldownText and cooldownText then
             local timeSinceLastBoost = currentTime - lastBoostTime
             if timeSinceLastBoost < cooldownDuration then
                 local remainingCooldown = cooldownDuration - timeSinceLastBoost
                 cooldownText.Text = "Boost CD: " .. string.format("%.1f", remainingCooldown) .. "s"
                 cooldownText.Color = {255, 100, 100}
             else
                 cooldownText.Text = "Jump Boost: Ready"
                 cooldownText.Color = {100, 255, 100}
             end
        end

        spacePressedLastFrame = spaceCurrentlyPressed
        wait()
    end
end

print("[Sen] FF2 jump boost loaded.")

spawn(keybindloop)
