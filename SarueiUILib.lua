--[[
    SarueiLib - A modern, elegant UI library for Severe
    Created by sen
]]

local SarueiUILib = {}
SarueiUILib.__index = SarueiUILib

local drawings = {}

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

local function createDrawing(type, properties)
    local drawing = Drawing.new(type)
    
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    
    table.insert(drawings, drawing)
    return drawing
end

local function removeDrawing(drawing)
    for i, v in pairs(drawings) do
        if v == drawing then
            table.remove(drawings, i)
            drawing:Remove()
            break
        end
    end
end

local theme = {
    background = {20, 20, 20},
    foreground = {30, 30, 30},
    accent = {255, 70, 70},
    text = {240, 240, 240},
    subText = {180, 180, 180},
    outline = {40, 40, 40},
    success = {70, 200, 70},
    warning = {230, 180, 40},
    error = {220, 60, 60}
}

function SarueiUILib.new(title, position, size)
    local screenSize = {getscreendimensions()}
    
    position = position or {50, 50}
    size = size or {300, 400}
    
    local window = setmetatable({
        title = title or "SarueiUILib",
        position = position,
        size = size,
        visible = true,
        dragging = false,
        dragOffset = {0, 0},
        elements = {},
        tabs = {},
        currentTab = nil,
        
        background = createDrawing("Square", {
            Size = {size[1], size[2]},
            Position = {position[1], position[2]},
            Color = theme.background,
            Filled = true,
            Visible = true,
            Transparency = 1,
            zIndex = 1
        }),
        
        titleBar = createDrawing("Square", {
            Size = {size[1], 30},
            Position = {position[1], position[2]},
            Color = theme.foreground,
            Filled = true,
            Visible = true,
            Transparency = 1,
            zIndex = 2
        }),
        
        titleText = createDrawing("Text", {
            Text = title or "SarueiUILib",
            Position = {position[1] + 10, position[2] + 8},
            Color = theme.text,
            Size = 14,
            Center = false,
            Outline = false,
            Visible = true,
            zIndex = 3
        }),
        
        closeButton = createDrawing("Square", {
            Size = {20, 20},
            Position = {position[1] + size[1] - 25, position[2] + 5},
            Color = theme.error,
            Filled = true,
            Visible = true,
            Transparency = 1,
            zIndex = 3
        }),
        
        closeX = createDrawing("Text", {
            Text = "×",
            Position = {position[1] + size[1] - 20, position[2] + 6},
            Color = theme.text,
            Size = 16,
            Center = true,
            Outline = false,
            Visible = true,
            zIndex = 4
        }),
        
        tabContainer = createDrawing("Square", {
            Size = {size[1], 30},
            Position = {position[1], position[2] + 30},
            Color = theme.foreground,
            Filled = true,
            Visible = true,
            Transparency = 1,
            zIndex = 2
        }),
        
        contentContainer = createDrawing("Square", {
            Size = {size[1], size[2] - 60},
            Position = {position[1], position[2] + 60},
            Color = theme.background,
            Filled = true,
            Visible = true,
            Transparency = 1,
            zIndex = 2
        })
    }, SarueiUILib)
    
    spawn(function()
        while true do
            if window.visible then
                local mousePos = {getmouseposition()}
                
                if isleftpressed() and window.dragging then
                    local newX = mousePos.x - window.dragOffset[1]
                    local newY = mousePos.y - window.dragOffset[2]
                    
                    window:setPosition({newX, newY})
                elseif isleftpressed() and mousePos.x >= window.position[1] and mousePos.x <= window.position[1] + window.size[1] and
                       mousePos.y >= window.position[2] and mousePos.y <= window.position[2] + 30 then
                    window.dragging = true
                    window.dragOffset = {mousePos.x - window.position[1], mousePos.y - window.position[2]}
                elseif not isleftpressed() then
                    window.dragging = false
                end
                
                if isleftclicked() and mousePos.x >= window.position[1] + window.size[1] - 25 and mousePos.x <= window.position[1] + window.size[1] - 5 and
                   mousePos.y >= window.position[2] + 5 and mousePos.y <= window.position[2] + 25 then
                    window:toggle()
                end
                
                if window.tabs and #window.tabs > 0 then
                    local tabWidth = window.size[1] / #window.tabs
                    
                    for i, tab in ipairs(window.tabs) do
                        local tabX = window.position[1] + (i - 1) * tabWidth
                        
                        if isleftclicked() and mousePos.x >= tabX and mousePos.x <= tabX + tabWidth and
                           mousePos.y >= window.position[2] + 30 and mousePos.y <= window.position[2] + 60 then
                            window:selectTab(i)
                        end
                    end
                end
                
                if window.currentTab then
                    for _, element in ipairs(window.currentTab.elements) do
                        if element.type == "button" then
                            if isleftclicked() and mousePos.x >= element.position[1] and mousePos.x <= element.position[1] + element.size[1] and
                               mousePos.y >= element.position[2] and mousePos.y <= element.position[2] + element.size[2] and element.visible then
                                if element.callback then
                                    element.callback()
                                end
                            end
                        elseif element.type == "toggle" then
                            if isleftclicked() and mousePos.x >= element.position[1] and mousePos.x <= element.position[1] + element.size[1] and
                               mousePos.y >= element.position[2] and mousePos.y <= element.position[2] + element.size[2] and element.visible then
                                element.value = not element.value
                                
                                if element.callback then
                                    element.callback(element.value)
                                end
                                
                                element.indicator.Color = element.value and theme.accent or theme.foreground
                            end
                        elseif element.type == "slider" then
                            if isleftpressed() and mousePos.x >= element.position[1] and mousePos.x <= element.position[1] + element.size[1] and
                               mousePos.y >= element.position[2] and mousePos.y <= element.position[2] + element.size[2] and element.visible then
                                local percentage = clamp((mousePos.x - element.position[1]) / element.size[1], 0, 1)
                                local value = lerp(element.min, element.max, percentage)
                                
                                if element.increment then
                                    value = math.floor(value / element.increment + 0.5) * element.increment
                                end
                                
                                element.value = value
                                
                                if element.callback then
                                    element.callback(element.value)
                                end
                                
                                element.fill.Size = {element.size[1] * percentage, element.size[2]}
                                element.valueText.Text = tostring(math.floor(element.value * 100) / 100)
                            end
                        elseif element.type == "dropdown" then
                            if isleftclicked() and mousePos.x >= element.position[1] and mousePos.x <= element.position[1] + element.size[1] and
                               mousePos.y >= element.position[2] and mousePos.y <= element.position[2] + element.size[2] and element.visible then
                                element.expanded = not element.expanded
                                
                                for i, option in ipairs(element.options) do
                                    option.background.Visible = element.expanded
                                    option.text.Visible = element.expanded
                                end
                            end
                            
                            if element.expanded then
                                for i, option in ipairs(element.options) do
                                    if isleftclicked() and mousePos.x >= option.background.Position[1] and mousePos.x <= option.background.Position[1] + option.background.Size[1] and
                                       mousePos.y >= option.background.Position[2] and mousePos.y <= option.background.Position[2] + option.background.Size[2] then
                                        element.value = option.value
                                        element.valueText.Text = option.text.Text
                                        element.expanded = false
                                        
                                        for j, opt in ipairs(element.options) do
                                            opt.background.Visible = false
                                            opt.text.Visible = false
                                        end
                                        
                                        if element.callback then
                                            element.callback(element.value)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            wait(0.01)
        end
    end)
    
    return window
end

function SarueiUILib:setPosition(position)
    local offsetX = position[1] - self.position[1]
    local offsetY = position[2] - self.position[2]
    
    self.position = position
    
    self.background.Position = position
    self.titleBar.Position = position
    self.titleText.Position = {position[1] + 10, position[2] + 8}
    self.closeButton.Position = {position[1] + self.size[1] - 25, position[2] + 5}
    self.closeX.Position = {position[1] + self.size[1] - 20, position[2] + 6}
    self.tabContainer.Position = {position[1], position[2] + 30}
    self.contentContainer.Position = {position[1], position[2] + 60}
    
    if self.tabs and #self.tabs > 0 then
        local tabWidth = self.size[1] / #self.tabs
        
        for i, tab in ipairs(self.tabs) do
            tab.background.Position = {position[1] + (i - 1) * tabWidth, position[2] + 30}
            tab.text.Position = {position[1] + (i - 1) * tabWidth + tabWidth / 2, position[2] + 38}
            
            for _, element in ipairs(tab.elements) do
                element.position = {element.position[1] + offsetX, element.position[2] + offsetY}
                
                if element.type == "label" then
                    element.text.Position = element.position
                elseif element.type == "button" then
                    element.background.Position = element.position
                    element.text.Position = {element.position[1] + element.size[1] / 2, element.position[2] + element.size[2] / 2 - 1}
                elseif element.type == "toggle" then
                    element.background.Position = element.position
                    element.text.Position = {element.position[1] + element.size[2] + 10, element.position[2] + element.size[2] / 2 - 1}
                    element.indicator.Position = {element.position[1] + 2, element.position[2] + 2}
                elseif element.type == "slider" then
                    element.background.Position = element.position
                    element.fill.Position = element.position
                    element.text.Position = {element.position[1], element.position[2] - 15}
                    element.valueText.Position = {element.position[1] + element.size[1], element.position[2] - 15}
                elseif element.type == "dropdown" then
                    element.background.Position = element.position
                    element.text.Position = {element.position[1] + 10, element.position[2] + element.size[2] / 2 - 1}
                    element.valueText.Position = {element.position[1] + element.size[1] - 20, element.position[2] + element.size[2] / 2 - 1}
                    element.arrow.Position = {element.position[1] + element.size[1] - 15, element.position[2] + element.size[2] / 2}
                    
                    for i, option in ipairs(element.options) do
                        option.background.Position = {element.position[1], element.position[2] + element.size[2] + (i - 1) * 25}
                        option.text.Position = {element.position[1] + 10, element.position[2] + element.size[2] + (i - 1) * 25 + 12}
                    end
                end
            end
        end
    end
end

function SarueiUILib:setSize(size)
    self.size = size
    
    self.background.Size = size
    self.titleBar.Size = {size[1], 30}
    self.closeButton.Position = {self.position[1] + size[1] - 25, self.position[2] + 5}
    self.closeX.Position = {self.position[1] + size[1] - 20, self.position[2] + 6}
    self.tabContainer.Size = {size[1], 30}
    self.contentContainer.Size = {size[1], size[2] - 60}
    
    if self.tabs and #self.tabs > 0 then
        local tabWidth = size[1] / #self.tabs
        
        for i, tab in ipairs(self.tabs) do
            tab.background.Size = {tabWidth, 30}
            tab.background.Position = {self.position[1] + (i - 1) * tabWidth, self.position[2] + 30}
            tab.text.Position = {self.position[1] + (i - 1) * tabWidth + tabWidth / 2, self.position[2] + 38}
        end
    end
end

function SarueiUILib:toggle()
    self.visible = not self.visible
    
    self.background.Visible = self.visible
    self.titleBar.Visible = self.visible
    self.titleText.Visible = self.visible
    self.closeButton.Visible = self.visible
    self.closeX.Visible = self.visible
    self.tabContainer.Visible = self.visible
    self.contentContainer.Visible = self.visible
    
    if self.tabs then
        for _, tab in ipairs(self.tabs) do
            tab.background.Visible = self.visible
            tab.text.Visible = self.visible
            
            if self.currentTab == tab then
                for _, element in ipairs(tab.elements) do
                    if element.type == "label" then
                        element.text.Visible = self.visible
                    elseif element.type == "button" then
                        element.background.Visible = self.visible
                        element.text.Visible = self.visible
                    elseif element.type == "toggle" then
                        element.background.Visible = self.visible
                        element.text.Visible = self.visible
                        element.indicator.Visible = self.visible
                    elseif element.type == "slider" then
                        element.background.Visible = self.visible
                        element.fill.Visible = self.visible
                        element.text.Visible = self.visible
                        element.valueText.Visible = self.visible
                    elseif element.type == "dropdown" then
                        element.background.Visible = self.visible
                        element.text.Visible = self.visible
                        element.valueText.Visible = self.visible
                        element.arrow.Visible = self.visible
                        
                        if not self.visible then
                            for _, option in ipairs(element.options) do
                                option.background.Visible = false
                                option.text.Visible = false
                            end
                        end
                    end
                end
            end
        end
    end
end

function SarueiUILib:addTab(name)
    local tabCount = #self.tabs + 1
    local tabWidth = self.size[1] / tabCount
    
    for i, tab in ipairs(self.tabs) do
        tab.background.Size = {tabWidth, 30}
        tab.background.Position = {self.position[1] + (i - 1) * tabWidth, self.position[2] + 30}
        tab.text.Position = {self.position[1] + (i - 1) * tabWidth + tabWidth / 2, self.position[2] + 38}
    end
    
    local tab = {
        name = name,
        elements = {},
        
        background = createDrawing("Square", {
            Size = {tabWidth, 30},
            Position = {self.position[1] + (tabCount - 1) * tabWidth, self.position[2] + 30},
            Color = self.currentTab == nil and theme.accent or theme.foreground,
            Filled = true,
            Visible = self.visible,
            Transparency = 1,
            zIndex = 3
        }),
        
        text = createDrawing("Text", {
            Text = name,
            Position = {self.position[1] + (tabCount - 1) * tabWidth + tabWidth / 2, self.position[2] + 38},
            Color = theme.text,
            Size = 14,
            Center = true,
            Outline = false,
            Visible = self.visible,
            zIndex = 4
        })
    }
    
    table.insert(self.tabs, tab)
    
    if #self.tabs == 1 then
        self.currentTab = tab
    end
    
    return tab
end

function SarueiUILib:selectTab(index)
    if self.tabs[index] then
        if self.currentTab then
            for _, element in ipairs(self.currentTab.elements) do
                if element.type == "label" then
                    element.text.Visible = false
                elseif element.type == "button" then
                    element.background.Visible = false
                    element.text.Visible = false
                elseif element.type == "toggle" then
                    element.background.Visible = false
                    element.text.Visible = false
                    element.indicator.Visible = false
                elseif element.type == "slider" then
                    element.background.Visible = false
                    element.fill.Visible = false
                    element.text.Visible = false
                    element.valueText.Visible = false
                elseif element.type == "dropdown" then
                    element.background.Visible = false
                    element.text.Visible = false
                    element.valueText.Visible = false
                    element.arrow.Visible = false
                    
                    for _, option in ipairs(element.options) do
                        option.background.Visible = false
                        option.text.Visible = false
                    end
                end
            end
            
            self.currentTab.background.Color = theme.foreground
        end
        
        self.currentTab = self.tabs[index]
        self.currentTab.background.Color = theme.accent
        
        for _, element in ipairs(self.currentTab.elements) do
            if element.type == "label" then
                element.text.Visible = self.visible
            elseif element.type == "button" then
                element.background.Visible = self.visible
                element.text.Visible = self.visible
            elseif element.type == "toggle" then
                element.background.Visible = self.visible
                element.text.Visible = self.visible
                element.indicator.Visible = self.visible
            elseif element.type == "slider" then
                element.background.Visible = self.visible
                element.fill.Visible = self.visible
                element.text.Visible = self.visible
                element.valueText.Visible = self.visible
            elseif element.type == "dropdown" then
                element.background.Visible = self.visible
                element.text.Visible = self.visible
                element.valueText.Visible = self.visible
                element.arrow.Visible = self.visible
            end
        end
    end
end

function SarueiUILib:addLabel(text, position)
    if not self.currentTab then
        return nil
    end
    
    local yPos = position or (#self.currentTab.elements * 30 + 10)
    
    local label = {
        type = "label",
        text = createDrawing("Text", {
            Text = text,
            Position = {self.position[1] + 10, self.position[2] + 70 + yPos},
            Color = theme.text,
            Size = 14,
            Center = false,
            Outline = false,
            Visible = self.visible,
            zIndex = 5
        }),
        position = {self.position[1] + 10, self.position[2] + 70 + yPos},
        visible = true
    }
    
    table.insert(self.currentTab.elements, label)
    return label
end

function SarueiUILib:addButton(text, callback, position, size)
    if not self.currentTab then
        return nil
    end
    
    local yPos = position or (#self.currentTab.elements * 30 + 10)
    local buttonSize = size or {self.size[1] - 20, 25}
    
    local button = {
        type = "button",
        callback = callback,
        position = {self.position[1] + 10, self.position[2] + 70 + yPos},
        size = buttonSize,
        visible = true,
        
        background = createDrawing("Square", {
            Size = buttonSize,
            Position = {self.position[1] + 10, self.position[2] + 70 + yPos},
            Color = theme.foreground,
            Filled = true,
            Visible = self.visible,
            Transparency = 1,
            zIndex = 5
        }),
        
        text = createDrawing("Text", {
            Text = text,
            Position = {self.position[1] + 10 + buttonSize[1] / 2, self.position[2] + 70 + yPos + buttonSize[2] / 2 - 1},
            Color = theme.text,
            Size = 14,
            Center = true,
            Outline = false,
            Visible = self.visible,
            zIndex = 6
        })
    }
    
    table.insert(self.currentTab.elements, button)
    return button
end

function SarueiUILib:addToggle(text, default, callback, position)
    if not self.currentTab then
        return nil
    end
    
    local yPos = position or (#self.currentTab.elements * 30 + 10)
    local toggleSize = {20, 20}
    
    local toggle = {
        type = "toggle",
        value = default or false,
        callback = callback,
        position = {self.position[1] + 10, self.position[2] + 70 + yPos},
        size = toggleSize,
        visible = true,
        
        background = createDrawing("Square", {
            Size = toggleSize,
            Position = {self.position[1] + 10, self.position[2] + 70 + yPos},
            Color = theme.foreground,
            Filled = true,
            Visible = self.visible,
            Transparency = 1,
            zIndex = 5
        }),
        
        indicator = createDrawing("Square", {
            Size = {toggleSize[1] - 4, toggleSize[2] - 4},
            Position = {self.position[1] + 12, self.position[2] + 72 + yPos},
            Color = default and theme.accent or theme.foreground,
            Filled = true,
            Visible = self.visible,
            Transparency = 1,
            zIndex = 6
        }),
        
        text = createDrawing("Text", {
            Text = text,
            Position = {self.position[1] + 10 + toggleSize[1] + 10, self.position[2] + 70 + yPos + toggleSize[2] / 2 - 1},
            Color = theme.text,
            Size = 14,
            Center = false,
            Outline = false,
            Visible = self.visible,
            zIndex = 6
        })
    }
    
    table.insert(self.currentTab.elements, toggle)
    return toggle
end

function SarueiUILib:addSlider(text, min, max, default, increment, callback, position)
    if not self.currentTab then
        return nil
    end
    
    local yPos = position or (#self.currentTab.elements * 30 + 10)
    local sliderSize = {self.size[1] - 20, 10}
    
    local value = default or min
    local percentage = (value - min) / (max - min)
    
    local slider = {
        type = "slider",
        value = value,
        min = min,
        max = max,
        increment = increment,
        callback = callback,
        position = {self.position[1] + 10, self.position[2] + 85 + yPos},
        size = sliderSize,
        visible = true,
        
        background = createDrawing("Square", {
            Size = sliderSize,
            Position = {self.position[1] + 10, self.position[2] + 85 + yPos},
            Color = theme.foreground,
            Filled = true,
            Visible = self.visible,
            Transparency = 1,
            zIndex = 5
        }),
        
        fill = createDrawing("Square", {
            Size = {sliderSize[1] * percentage, sliderSize[2]},
            Position = {self.position[1] + 10, self.position[2] + 85 + yPos},
            Color = theme.accent,
            Filled = true,
            Visible = self.visible,
            Transparency = 1,
            zIndex = 6
        }),
        
        text = createDrawing("Text", {
            Text = text,
            Position = {self.position[1] + 10, self.position[2] + 70 + yPos},
            Color = theme.text,
            Size = 14,
            Center = false,
            Outline = false,
            Visible = self.visible,
            zIndex = 6
        }),
        
        valueText = createDrawing("Text", {
            Text = tostring(value),
            Position = {self.position[1] + 10 + sliderSize[1], self.position[2] + 70 + yPos},
            Color = theme.subText,
            Size = 14,
            Center = true,
            Outline = false,
            Visible = self.visible,
            zIndex = 6
        })
    }
    
    table.insert(self.currentTab.elements, slider)
    return slider
end

function SarueiUILib:addDropdown(text, options, default, callback, position)
    if not self.currentTab then
        return nil
    end
    
    local yPos = position or (#self.currentTab.elements * 30 + 10)
    local dropdownSize = {self.size[1] - 20, 25}
    
    local dropdown = {
        type = "dropdown",
        options = {},
        value = default or options[1],
        expanded = false,
        callback = callback,
        position = {self.position[1] + 10, self.position[2] + 70 + yPos},
        size = dropdownSize,
        visible = true,
        
        background = createDrawing("Square", {
            Size = dropdownSize,
            Position = {self.position[1] + 10, self.position[2] + 70 + yPos},
            Color = theme.foreground,
            Filled = true,
            Visible = self.visible,
            Transparency = 1,
            zIndex = 5
        }),
        
        text = createDrawing("Text", {
            Text = text,
            Position = {self.position[1] + 20, self.position[2] + 70 + yPos + dropdownSize[2] / 2 - 1},
            Color = theme.text,
            Size = 14,
            Center = false,
            Outline = false,
            Visible = self.visible,
            zIndex = 6
        }),
        
        valueText = createDrawing("Text", {
            Text = default or options[1],
            Position = {self.position[1] + 10 + dropdownSize[1] - 20, self.position[2] + 70 + yPos + dropdownSize[2] / 2 - 1},
            Color = theme.subText,
            Size = 14,
            Center = true,
            Outline = false,
            Visible = self.visible,
            zIndex = 6
        }),
        
        arrow = createDrawing("Text", {
            Text = "▼",
            Position = {self.position[1] + 10 + dropdownSize[1] - 15, self.position[2] + 70 + yPos + dropdownSize[2] / 2 - 1},
            Color = theme.subText,
            Size = 12,
            Center = true,
            Outline = false,
            Visible = self.visible,
            zIndex = 6
        })
    }
    
        for i, option in ipairs(options) do
            local optionValue = option
            local optionText = option
            
            if type(option) == "table" then
                optionValue = option.value
                optionText = option.text
            end
            
            local optionElement = {
                value = optionValue,
                background = createDrawing("Square", {
                    Size = {dropdownSize[1], 25},
                    Position = {self.position[1] + 10, self.position[2] + 70 + yPos + dropdownSize[2] + (i - 1) * 25},
                    Color = theme.foreground,
                    Filled = true,
                    Visible = false,
                    Transparency = 1,
                    zIndex = 7
                }),
                
                text = createDrawing("Text", {
                    Text = optionText,
                    Position = {self.position[1] + 20, self.position[2] + 70 + yPos + dropdownSize[2] + (i - 1) * 25 + 12},
                    Color = theme.text,
                    Size = 14,
                    Center = false,
                    Outline = false,
                    Visible = false,
                    zIndex = 8
                })
            }
            
            table.insert(dropdown.options, optionElement)
        end
        
        table.insert(self.currentTab.elements, dropdown)
        return dropdown
    end
    
    function SarueiUILib:addColorPicker(text, default, callback, position)
        if not self.currentTab then
            return nil
        end
        
        local yPos = position or (#self.currentTab.elements * 30 + 10)
        local pickerSize = {20, 20}
        
        default = default or {255, 255, 255}
        
        local colorPicker = {
            type = "colorpicker",
            value = default,
            callback = callback,
            position = {self.position[1] + 10, self.position[2] + 70 + yPos},
            size = pickerSize,
            visible = true,
            expanded = false,
            
            background = createDrawing("Square", {
                Size = pickerSize,
                Position = {self.position[1] + 10, self.position[2] + 70 + yPos},
                Color = default,
                Filled = true,
                Visible = self.visible,
                Transparency = 1,
                zIndex = 5
            }),
            
            text = createDrawing("Text", {
                Text = text,
                Position = {self.position[1] + 10 + pickerSize[1] + 10, self.position[2] + 70 + yPos + pickerSize[2] / 2 - 1},
                Color = theme.text,
                Size = 14,
                Center = false,
                Outline = false,
                Visible = self.visible,
                zIndex = 6
            })
        }
        
        table.insert(self.currentTab.elements, colorPicker)
        return colorPicker
    end
    
    function SarueiUILib:destroy()
        for _, drawing in pairs(drawings) do
            drawing:Remove()
        end
        
        drawings = {}
    end
    
    function SarueiUILib:setTheme(newTheme)
        for key, value in pairs(newTheme) do
            if theme[key] then
                theme[key] = value
            end
        end
        
        if self.background then
            self.background.Color = theme.background
            self.titleBar.Color = theme.foreground
            self.titleText.Color = theme.text
            self.closeButton.Color = theme.error
            self.closeX.Color = theme.text
            self.tabContainer.Color = theme.foreground
            self.contentContainer.Color = theme.background
            
            if self.tabs then
                for i, tab in ipairs(self.tabs) do
                    tab.background.Color = tab == self.currentTab and theme.accent or theme.foreground
                    tab.text.Color = theme.text
                    
                    for _, element in ipairs(tab.elements) do
                        if element.type == "label" then
                            element.text.Color = theme.text
                        elseif element.type == "button" then
                            element.background.Color = theme.foreground
                            element.text.Color = theme.text
                        elseif element.type == "toggle" then
                            element.background.Color = theme.foreground
                            element.text.Color = theme.text
                            element.indicator.Color = element.value and theme.accent or theme.foreground
                        elseif element.type == "slider" then
                            element.background.Color = theme.foreground
                            element.fill.Color = theme.accent
                            element.text.Color = theme.text
                            element.valueText.Color = theme.subText
                        elseif element.type == "dropdown" then
                            element.background.Color = theme.foreground
                            element.text.Color = theme.text
                            element.valueText.Color = theme.subText
                            element.arrow.Color = theme.subText
                            
                            for _, option in ipairs(element.options) do
                                option.background.Color = theme.foreground
                                option.text.Color = theme.text
                            end
                        elseif element.type == "colorpicker" then
                            element.text.Color = theme.text
                        end
                    end
                end
            end
        end
    end
    
    function SarueiUILib:getTheme()
        return theme
    end
    
    function SarueiUILib.createNotification(text, duration, type)
        duration = duration or 3
        type = type or "info"
        
        local typeColors = {
            info = theme.accent,
            success = theme.success,
            warning = theme.warning,
            error = theme.error
        }
        
        local color = typeColors[type] or theme.accent
        local screenSize = {getscreendimensions()}
        local notifWidth = 200
        local notifHeight = 40
        
        local notification = {
            background = createDrawing("Square", {
                Size = {notifWidth, notifHeight},
                Position = {screenSize[1] - notifWidth - 20, screenSize[2] - notifHeight - 20},
                Color = theme.background,
                Filled = true,
                Visible = true,
                Transparency = 0.95,
                zIndex = 100
            }),
            
            accent = createDrawing("Square", {
                Size = {3, notifHeight},
                Position = {screenSize[1] - notifWidth - 20, screenSize[2] - notifHeight - 20},
                Color = color,
                Filled = true,
                Visible = true,
                Transparency = 1,
                zIndex = 101
            }),
            
            text = createDrawing("Text", {
                Text = text,
                Position = {screenSize[1] - notifWidth - 10, screenSize[2] - notifHeight - 20 + notifHeight / 2 - 7},
                Color = theme.text,
                Size = 14,
                Center = false,
                Outline = false,
                Visible = true,
                zIndex = 102
            })
        }
        
        spawn(function()
            wait(duration)
            
            for _ = 1, 10 do
                notification.background.Transparency = notification.background.Transparency - 0.1
                notification.accent.Transparency = notification.accent.Transparency - 0.1
                notification.text.Transparency = notification.text.Transparency - 0.1
                wait(0.05)
            end
            
            removeDrawing(notification.background)
            removeDrawing(notification.accent)
            removeDrawing(notification.text)
        end)
        
        return notification
    end
    
    function SarueiUILib:addKeybind(text, default, callback, position)
        if not self.currentTab then
            return nil
        end
        
        local yPos = position or (#self.currentTab.elements * 30 + 10)
        local keybindSize = {60, 20}
        
        local keybind = {
            type = "keybind",
            key = default,
            callback = callback,
            position = {self.position[1] + self.size[1] - 70, self.position[2] + 70 + yPos},
            size = keybindSize,
            visible = true,
            listening = false,
            
            background = createDrawing("Square", {
                Size = keybindSize,
                Position = {self.position[1] + self.size[1] - 70, self.position[2] + 70 + yPos},
                Color = theme.foreground,
                Filled = true,
                Visible = self.visible,
                Transparency = 1,
                zIndex = 5
            }),
            
            text = createDrawing("Text", {
                Text = text,
                Position = {self.position[1] + 10, self.position[2] + 70 + yPos + 10},
                Color = theme.text,
                Size = 14,
                Center = false,
                Outline = false,
                Visible = self.visible,
                zIndex = 6
            }),
            
            keyText = createDrawing("Text", {
                Text = default or "...",
                Position = {self.position[1] + self.size[1] - 40, self.position[2] + 70 + yPos + 10},
                Color = theme.subText,
                Size = 14,
                Center = true,
                Outline = false,
                Visible = self.visible,
                zIndex = 6
            })
        }
        
        spawn(function()
            while true do
                if keybind.listening then
                    local key = getpressedkey()
                    if key then
                        keybind.key = key
                        keybind.keyText.Text = key
                        keybind.listening = false
                        keybind.background.Color = theme.foreground
                    end
                end
                
                if keybind.key then
                    if iskeydown(keybind.key) and keybind.callback then
                        keybind.callback()
                    end
                end
                
                wait(0.01)
            end
        end)
        
        table.insert(self.currentTab.elements, keybind)
        return keybind
    end
    
    return SarueiUILib
