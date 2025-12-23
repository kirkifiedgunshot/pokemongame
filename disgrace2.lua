--// Modern Merchant GUI (Complete Feature Set)
--// Features: Checkboxes, Select All, Delete Config, Auto-Load Manager, Tooltips

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local PurchaseRemote = ReplicatedStorage:WaitForChild("NetworkEvents"):WaitForChild("PURCHASE_SHOP_STOCK")

--== FILE SYSTEM ==--
local MAIN_SETTINGS_FILE = "MerchantGUI_Settings.json" 
local function getFileName(name) return "MerchantCfg_" .. name .. ".json" end

-- Global Settings (which config to load on start)
local Settings = {
    AutoLoadConfigName = "Default", -- The config to load automatically
    AutoLoadEnabled = true
}

-- Current Active Config (The actual purchase settings)
local Config = {
    SelectedItems = {}, -- Key = item.key, Value = true/false
    AutoBuyEnabled = false,
    AutoBuyDelay = 1,
    ConfigName = "Default" -- Name of currently loaded config
}

--== ITEM DATA ==--
local Items = {
    {display = "Petcoins Potion",        key = "items:petcoins_potion",         price = 29},
    {display = "EXP Potion",             key = "items:exp_potion",              price = 29},
    {display = "Sandwich",               key = "items:sandwich",                price = 29},
    {display = "Superpotion",            key = "items:superpotion",             price = 29},
    {display = "Bubble Gum",             key = "items:bubble_gum",              price = 29},
    {display = "Special Mount",          key = "items:special_mount",           price = 49},
    {display = "Cookies",                key = "items:cookies",                 price = 69},
    {display = "Cake",                   key = "items:cake",                    price = 69},
    {display = "Paella",                 key = "items:paella",                  price = 99},
    {display = "Gyozas",                 key = "items:gyozas",                  price = 99},
    {display = "Legendary Luck",         key = "items:legendary_luck",          price = 129},
    {display = "Celestial Luck",         key = "items:celestial_luck",          price = 129},
    {display = "Electric Bicycle",       key = "items:electric_bicycle",        price = 149000},
    {display = "Shiny Star",             key = "items:shiny_star",              price = 799},
    {display = "Super Candy",            key = "items:super_candy",             price = 799},
    {display = "Incense",                key = "items:incense",                 price = 5000},
    {display = "Meteorite",              key = "items:meteorite",               price = 5000},
    {display = "x2 Celestial Luck!",     key = "items:x2_celestial_luck!",      price = 1500000},
    {display = "Dragon Evolution Stone", key = "items:dragon_evolution_stone",  price = 29},
    {display = "Grass Evolution Stone",  key = "items:grass_evolution_stone",   price = 29},
    {display = "Ground Evolution Stone", key = "items:ground_evolution_stone",  price = 29},
    {display = "Normal Evolution Stone", key = "items:normal_evolution_stone",  price = 29},
    {display = "Poison Evolution Stone", key = "items:poison_evolution_stone",  price = 29},
    {display = "Rock Evolution Stone",   key = "items:rock_evolution_stone",    price = 29},
    {display = "Water Evolution Stone",  key = "items:water_evolution_stone",   price = 29},
    {display = "Psychic Evolution Stone",key = "items:psychic_evolution_stone", price = 29},
    {display = "Fairy Evolution Stone",  key = "items:fairy_evolution_stone",   price = 29},
    {display = "Bug Evolution Stone",    key = "items:bug_evolution_stone",     price = 29},
    {display = "Ice Evolution Stone",    key = "items:ice_evolution_stone",     price = 29},
    {display = "Dark Evolution Stone",   key = "items:dark_evolution_stone",    price = 29},
    {display = "Steel Evolution Stone",  key = "items:steel_evolution_stone",   price = 29},
    {display = "Electric Evolution Stone", key = "items:electric_evolution_stone", price = 29},
    {display = "Fighting Evolution Stone", key = "items:fighting_evolution_stone", price = 29},
    {display = "Fire Evolution Stone",   key = "items:fire_evolution_stone",    price = 29},
    {display = "Flying Evolution Stone", key = "items:flying_evolution_stone",  price = 29},
    {display = "Ghost Evolution Stone",  key = "items:ghost_evolution_stone",   price = 29},
}

-- Sort into categories
local Categories = {
    Potions = {},
    Foods = {},
    Stones = {}
}

for _, item in ipairs(Items) do
    local name = item.display:lower()
    if name:find("potion") or name:find("luck") or name:find("candy") or name:find("incense") or name:find("meteorite") or name:find("star") then
        table.insert(Categories.Potions, item)
    elseif name:find("sandwich") or name:find("bubble gum") or name:find("cookies") or name:find("cake") or name:find("paella") or name:find("gyozas") then
        table.insert(Categories.Foods, item)
    elseif name:find("evolution stone") or name:find("stone") then
        table.insert(Categories.Stones, item)
    else
        table.insert(Categories.Potions, item)
    end
end

--== IO FUNCTIONS ==--
local function saveMainSettings()
    if writefile then writefile(MAIN_SETTINGS_FILE, HttpService:JSONEncode(Settings)) end
end

local function loadMainSettings()
    if isfile and isfile(MAIN_SETTINGS_FILE) then
        local s, r = pcall(function() return HttpService:JSONDecode(readfile(MAIN_SETTINGS_FILE)) end)
        if s and type(r) == "table" then
            for k,v in pairs(r) do Settings[k] = v end
        end
    end
end

local function saveConfig(name)
    local data = {
        SelectedItems = Config.SelectedItems,
        AutoBuyEnabled = Config.AutoBuyEnabled,
        AutoBuyDelay = Config.AutoBuyDelay
    }
    if writefile then
        writefile(getFileName(name), HttpService:JSONEncode(data))
        Config.ConfigName = name
    end
end

local function loadConfig(name)
    local fname = getFileName(name)
    if isfile and isfile(fname) then
        local s, r = pcall(function() return HttpService:JSONDecode(readfile(fname)) end)
        if s and type(r) == "table" then
            Config.SelectedItems = r.SelectedItems or {}
            Config.AutoBuyEnabled = r.AutoBuyEnabled or false
            Config.AutoBuyDelay = r.AutoBuyDelay or 1
            Config.ConfigName = name
            return true
        end
    end
    return false
end

local function deleteConfig(name)
    local fname = getFileName(name)
    if isfile and isfile(fname) and delfile then
        delfile(fname)
        return true
    end
    return false
end

local function listConfigs()
    local list = {"Default"}
    if listfiles then
        for _, file in ipairs(listfiles("")) do
            if file:find("MerchantCfg_") and file:find(".json") then
                local n = file:match("MerchantCfg_(.+)%.json")
                if n and n ~= "Default" then table.insert(list, n) end
            end
        end
    end
    return list
end

-- Initial Load
loadMainSettings()
if Settings.AutoLoadEnabled then
    loadConfig(Settings.AutoLoadConfigName)
end

--== UI HELPERS ==--
local function create(class, props, children)
    local inst = Instance.new(class)
    for k,v in pairs(props) do inst[k] = v end
    if children then for _,c in pairs(children) do c.Parent = inst end end
    return inst
end

local C_BG = Color3.fromRGB(24, 24, 27)
local C_MAIN = Color3.fromRGB(31, 31, 35)
local C_ACCENT = Color3.fromRGB(50, 50, 60)
local C_TEXT = Color3.fromRGB(220, 220, 220)
local C_TEXT_DIM = Color3.fromRGB(160, 160, 170)
local C_GREEN = Color3.fromRGB(100, 200, 100)
local C_RED = Color3.fromRGB(200, 80, 80)
local C_BLUE = Color3.fromRGB(80, 140, 220)

-- Tooltip logic
local TooltipLabel
local function addTooltip(obj, text)
    obj.MouseEnter:Connect(function()
        if not TooltipLabel then return end
        TooltipLabel.Text = text
        TooltipLabel.Visible = true
    end)
    obj.MouseLeave:Connect(function()
        if TooltipLabel then TooltipLabel.Visible = false end
    end)
    -- Follow mouse
    obj.MouseMoved:Connect(function(x, y)
        if TooltipLabel then
            TooltipLabel.Position = UDim2.new(0, x + 15, 0, y + 15)
        end
    end)
end

--== MAIN GUI ==--
local ScreenGui = create("ScreenGui", { Name = "MerchantUltimate", Parent = LocalPlayer:WaitForChild("PlayerGui"), ResetOnSpawn = false, DisplayOrder = 100 })
TooltipLabel = create("TextLabel", {
    Parent = ScreenGui, Visible = false, ZIndex = 200, BackgroundColor3 = C_BG, TextColor3 = C_TEXT,
    Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY, Font = Enum.Font.Code, TextSize = 12,
    BorderSizePixel = 0
}, { create("UICorner", {CornerRadius = UDim.new(0, 4)}), create("UIPadding", {PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4), PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6)}) })

local MainFrame = create("Frame", {
    Name = "MainFrame", Size = UDim2.new(0, 360, 0, 500), Position = UDim2.new(0.5, -180, 0.5, -250),
    BackgroundColor3 = C_BG, Parent = ScreenGui, ClipsDescendants = true
}, { create("UICorner", {CornerRadius = UDim.new(0, 8)}), create("UIStroke", {Color = C_ACCENT}) })

-- Dragging
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = MainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local d = i.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
UserInputService.InputBegan:Connect(function(i,g) if not g and i.KeyCode == Enum.KeyCode.LeftControl then MainFrame.Visible = not MainFrame.Visible end end)

-- Header
local TopBar = create("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = MainFrame })
create("TextLabel", { Parent = TopBar, Text = "  MERCHANT UTILITY", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C_TEXT, Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
local CloseBtn = create("TextButton", { Parent = TopBar, Text = "X", Font = Enum.Font.GothamBold, TextColor3 = C_RED, Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(1, -32, 0, 0), BackgroundTransparency = 1 })
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Tab Buttons
local TabContainer = create("Frame", { Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 0, 32), BackgroundColor3 = C_MAIN, Parent = MainFrame }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}) })
local MerchantBtn = create("TextButton", { Parent = TabContainer, Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = "Merchant", Font = Enum.Font.GothamMedium, TextColor3 = C_TEXT, TextSize = 13 })
local ConfigBtn = create("TextButton", { Parent = TabContainer, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, Text = "Config", Font = Enum.Font.GothamMedium, TextColor3 = C_TEXT_DIM, TextSize = 13 })
local Indicator = create("Frame", { Parent = TabContainer, Size = UDim2.new(0.5, -4, 0, 2), Position = UDim2.new(0, 2, 1, -2), BackgroundColor3 = C_GREEN, BorderSizePixel = 0 })

-- Pages
local PageContainer = create("Frame", { Size = UDim2.new(1, -16, 1, -74), Position = UDim2.new(0, 8, 0, 70), BackgroundTransparency = 1, Parent = MainFrame })
local MerchantPage = create("ScrollingFrame", { Parent = PageContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = C_ACCENT, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0) })
local ConfigPage = create("ScrollingFrame", { Parent = PageContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 2, ScrollBarImageColor3 = C_ACCENT })

create("UIListLayout", { Parent = MerchantPage, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
create("UIPadding", { Parent = MerchantPage, PaddingRight = UDim.new(0, 4) })
create("UIListLayout", { Parent = ConfigPage, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })

-- Switch Tabs
MerchantBtn.MouseButton1Click:Connect(function() MerchantPage.Visible = true; ConfigPage.Visible = false; MerchantBtn.TextColor3 = C_TEXT; ConfigBtn.TextColor3 = C_TEXT_DIM; Indicator:TweenPosition(UDim2.new(0, 2, 1, -2), "Out", "Quad", 0.2) end)
ConfigBtn.MouseButton1Click:Connect(function() MerchantPage.Visible = false; ConfigPage.Visible = true; MerchantBtn.TextColor3 = C_TEXT_DIM; ConfigBtn.TextColor3 = C_TEXT; Indicator:TweenPosition(UDim2.new(0.5, 2, 1, -2), "Out", "Quad", 0.2) end)

--== MERCHANT PAGE LOGIC ==--

-- Function to create category with select all and checkboxes
local function createCategory(name, items, order)
    local Wrapper = create("Frame", { Parent = MerchantPage, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C_MAIN, LayoutOrder = order, ClipsDescendants = true }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}), create("UIStroke", {Color = C_ACCENT}) })
    
    local Header = create("TextButton", { Parent = Wrapper, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "", ZIndex = 2 })
    create("TextLabel", { Parent = Header, Text = name, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C_TEXT, Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    local Arrow = create("TextLabel", { Parent = Header, Text = "+", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C_TEXT_DIM, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1 })

    -- Select All Button
    local SelectAllBtn = create("TextButton", { Parent = Header, Size = UDim2.new(0, 60, 0, 20), Position = UDim2.new(1, -100, 0, 8), BackgroundColor3 = C_ACCENT, Text = "Select All", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C_TEXT, ZIndex = 3 }, { create("UICorner", {CornerRadius = UDim.new(0, 4)}) })
    addTooltip(SelectAllBtn, "Toggle all items in this category")

    local ItemContainer = create("Frame", { Parent = Wrapper, Size = UDim2.new(1, -16, 0, 0), Position = UDim2.new(0, 8, 0, 36), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    local List = create("UIListLayout", { Parent = ItemContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
    
    local itemToggles = {} -- Store references

    -- Items
    for _, item in ipairs(items) do
        local row = create("Frame", { Parent = ItemContainer, Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C_BG }, { create("UICorner", {CornerRadius = UDim.new(0, 4)}) })
        
        -- Checkbox
        local check = create("TextButton", { Parent = row, Size = UDim2.new(0, 24, 0, 24), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C_GREEN })
        local box = create("Frame", { Parent = check, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0.5, -7, 0.5, -7), BackgroundColor3 = C_MAIN, BorderColor3 = C_TEXT_DIM, BorderSizePixel = 1 })
        
        -- Update visual
        local function updateCheck()
            if Config.SelectedItems[item.key] then
                box.BackgroundColor3 = C_GREEN
            else
                box.BackgroundColor3 = C_MAIN
            end
        end
        updateCheck()
        itemToggles[item.key] = updateCheck

        check.MouseButton1Click:Connect(function()
            Config.SelectedItems[item.key] = not Config.SelectedItems[item.key]
            updateCheck()
        end)

        -- Text
        create("TextLabel", { Parent = row, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 30, 0, 0), BackgroundTransparency = 1, Text = item.display .. "  [$" .. item.price .. "]", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C_TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Left })
    end

    -- Select All Logic
    SelectAllBtn.MouseButton1Click:Connect(function()
        local allSelected = true
        for _, item in ipairs(items) do if not Config.SelectedItems[item.key] then allSelected = false break end end
        
        for _, item in ipairs(items) do
            Config.SelectedItems[item.key] = not allSelected
            if itemToggles[item.key] then itemToggles[item.key]() end
        end
    end)

    -- Expansion Logic
    local expanded = false
    Header.MouseButton1Click:Connect(function()
        expanded = not expanded
        Arrow.Text = expanded and "-" or "+"
        local h = expanded and (List.AbsoluteContentSize.Y + 44) or 36
        TweenService:Create(Wrapper, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, h)}):Play()
    end)
end

createCategory("Potions & Utility", Categories.Potions, 1)
createCategory("Food Items", Categories.Foods, 2)
createCategory("Evolution Stones", Categories.Stones, 3)

-- Auto Buy Controls
local AutoBuyPanel = create("Frame", { Parent = MerchantPage, LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C_MAIN }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}), create("UIStroke", {Color = C_ACCENT}) })
local ToggleBtn = create("TextButton", { Parent = AutoBuyPanel, Size = UDim2.new(0, 120, 0, 32), Position = UDim2.new(0, 12, 0, 14), BackgroundColor3 = C_RED, Text = "AUTO BUY: OFF", Font = Enum.Font.GothamBold, TextColor3 = C_TEXT, TextSize = 12 }, { create("UICorner", {CornerRadius = UDim.new(0, 4)}) })
addTooltip(ToggleBtn, "Starts buying all selected items repeatedly")

local function updateMasterToggle()
    ToggleBtn.Text = "AUTO BUY: " .. (Config.AutoBuyEnabled and "ON" or "OFF")
    ToggleBtn.BackgroundColor3 = Config.AutoBuyEnabled and C_GREEN or C_RED
end
updateMasterToggle()
ToggleBtn.MouseButton1Click:Connect(function() Config.AutoBuyEnabled = not Config.AutoBuyEnabled; updateMasterToggle() end)

local DelayInput = create("TextBox", { Parent = AutoBuyPanel, Size = UDim2.new(0, 50, 0, 30), Position = UDim2.new(1, -62, 0, 15), BackgroundColor3 = C_BG, Text = tostring(Config.AutoBuyDelay), TextColor3 = C_TEXT, Font = Enum.Font.Gotham, TextSize = 12 }, { create("UICorner", {CornerRadius = UDim.new(0, 4)}), create("UIStroke", {Color = C_ACCENT}) })
create("TextLabel", { Parent = AutoBuyPanel, Text = "Delay (s):", Position = UDim2.new(1, -130, 0, 15), Size = UDim2.new(0, 60, 0, 30), BackgroundTransparency = 1, TextColor3 = C_TEXT_DIM, Font = Enum.Font.Gotham, TextSize = 12 })
addTooltip(DelayInput, "Time in seconds between purchase attempts")
DelayInput.FocusLost:Connect(function() local n = tonumber(DelayInput.Text); if n then Config.AutoBuyDelay = n else DelayInput.Text = tostring(Config.AutoBuyDelay) end end)

--== CONFIG PAGE LOGIC ==--

-- Info Labels
local StatusLabel = create("TextLabel", { Parent = ConfigPage, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Current Config: " .. Config.ConfigName, TextColor3 = C_GREEN, Font = Enum.Font.Code, TextSize = 12 })
local AutoLoadLabel = create("TextLabel", { Parent = ConfigPage, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Auto-Load: " .. (Settings.AutoLoadEnabled and Settings.AutoLoadConfigName or "Disabled"), TextColor3 = C_BLUE, Font = Enum.Font.Code, TextSize = 12 })

local function updateInfo()
    StatusLabel.Text = "Current Config: " .. Config.ConfigName
    AutoLoadLabel.Text = "Auto-Load: " .. (Settings.AutoLoadEnabled and Settings.AutoLoadConfigName or "Disabled")
end

-- Create/Save
local NameInput = create("TextBox", { Parent = ConfigPage, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C_MAIN, PlaceholderText = "Enter config name...", Text = "", TextColor3 = C_TEXT, Font = Enum.Font.Gotham, TextSize = 13 }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}), create("UIStroke", {Color = C_ACCENT}) })
addTooltip(NameInput, "Type a name for a new or existing config")

local SaveBtn = create("TextButton", { Parent = ConfigPage, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C_ACCENT, Text = "Save Current Settings", Font = Enum.Font.GothamBold, TextColor3 = C_TEXT, TextSize = 13 }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}) })
addTooltip(SaveBtn, "Saves selected items and settings to file")
SaveBtn.MouseButton1Click:Connect(function()
    local n = NameInput.Text
    if n == "" then n = Config.ConfigName end
    saveConfig(n)
    updateInfo()
    -- Refresh list
    -- (We will implement a refresh function call below)
end)

-- List of Configs
local ConfigListFrame = create("Frame", { Parent = ConfigPage, LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
local ConfigLayout = create("UIListLayout", { Parent = ConfigListFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })

local function refreshConfigList()
    ConfigListFrame:ClearAllChildren()
    create("UIListLayout", { Parent = ConfigListFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
    
    local files = listConfigs()
    for _, fname in ipairs(files) do
        local row = create("Frame", { Parent = ConfigListFrame, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C_MAIN }, { create("UICorner", {CornerRadius = UDim.new(0, 4)}) })
        
        -- Load
        local loadB = create("TextButton", { Parent = row, Size = UDim2.new(1, -120, 1, 0), BackgroundTransparency = 1, Text = "  " .. fname, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C_TEXT, Font = Enum.Font.Gotham, TextSize = 13 })
        addTooltip(loadB, "Click to LOAD this config")
        loadB.MouseButton1Click:Connect(function()
            if loadConfig(fname) then
                updateInfo()
                NameInput.Text = fname
                DelayInput.Text = tostring(Config.AutoBuyDelay)
                updateMasterToggle()
                -- Refresh checkboxes? You'd need to rebuild category UI or update toggles.
                -- For simplicity, user can toggle tabs to refresh or we force a rebuild.
                -- Let's just notify loaded.
            end
        end)
        
        -- Set as Main
        local mainB = create("TextButton", { Parent = row, Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -90, 0, 0), BackgroundColor3 = C_BLUE, Text = "Main", TextColor3 = C_TEXT, Font = Enum.Font.GothamBold, TextSize = 10 })
        addTooltip(mainB, "Set as the Auto-Load config")
        mainB.MouseButton1Click:Connect(function()
            Settings.AutoLoadConfigName = fname
            Settings.AutoLoadEnabled = true
            saveMainSettings()
            updateInfo()
        end)
        
        -- Delete
        local delB = create("TextButton", { Parent = row, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -30, 0, 0), BackgroundColor3 = C_RED, Text = "X", TextColor3 = C_TEXT, Font = Enum.Font.GothamBold, TextSize = 12 })
        addTooltip(delB, "DELETE this config file permanently")
        delB.MouseButton1Click:Connect(function()
            deleteConfig(fname)
            refreshConfigList()
        end)
    end
end

-- Refresh button
local RefreshBtn = create("TextButton", { Parent = ConfigPage, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "Refresh Config List", TextColor3 = C_TEXT_DIM, Font = Enum.Font.Gotham, TextSize = 12 })
RefreshBtn.MouseButton1Click:Connect(refreshConfigList)

-- Hook save to refresh
SaveBtn.MouseButton1Click:Connect(function()
    task.wait(0.1)
    refreshConfigList()
end)

refreshConfigList()
updateInfo()

--== MAIN LOOP ==--
task.spawn(function()
    while ScreenGui.Parent do
        if Config.AutoBuyEnabled then
            for key, enabled in pairs(Config.SelectedItems) do
                if enabled and Config.AutoBuyEnabled then
                    pcall(function() PurchaseRemote:InvokeServer(key, 1) end)
                end
            end
            task.wait(Config.AutoBuyDelay)
        else
            task.wait(0.2)
        end
    end
end)