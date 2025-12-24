--// Modern Merchant GUI + Advanced Farming
--// Features: Merchant Auto-Buy, Magnet, Single Farm, Group Farm, Config Saving

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Attempt to find the Purchase Remote (Merchant)
local PurchaseRemote = ReplicatedStorage:WaitForChild("NetworkEvents"):WaitForChild("PURCHASE_SHOP_STOCK")

--== FILE SYSTEM ==--
local MAIN_SETTINGS_FILE = "MerchantGUI_Settings.json"
local function getFileName(name) return "MerchantCfg_" .. name .. ".json" end

-- Global Settings (which config to load on start)
local Settings = {
    AutoLoadConfigName = "Default",
    AutoLoadEnabled = true
}

-- Current Active Config (The actual settings)
local Config = {
    -- Merchant
    SelectedItems = {},
    AutoBuyEnabled = false,
    AutoBuyDelay = 1,
    
    -- Farming / Magnet
    InfiniteMagnet = false,
    FarmRange = 300,        -- Default range
    Farm1Enabled = false,   -- Single Farm
    Farm2Enabled = false,   -- Group Farm

    ConfigName = "Default"
}

--== ITEM DATA (MERCHANT) ==--
local Items = {
    {display = "Petcoins Potion", key = "items:petcoins_potion", price = 29},
    {display = "EXP Potion", key = "items:exp_potion", price = 29},
    {display = "Sandwich", key = "items:sandwich", price = 29},
    {display = "Superpotion", key = "items:superpotion", price = 29},
    {display = "Bubble Gum", key = "items:bubble_gum", price = 29},
    {display = "Special Mount", key = "items:special_mount", price = 49},
    {display = "Cookies", key = "items:cookies", price = 69},
    {display = "Cake", key = "items:cake", price = 69},
    {display = "Paella", key = "items:paella", price = 99},
    {display = "Gyozas", key = "items:gyozas", price = 99},
    {display = "Legendary Luck", key = "items:legendary_luck", price = 129},
    {display = "Celestial Luck", key = "items:celestial_luck", price = 129},
    {display = "Electric Bicycle", key = "items:electric_bicycle", price = 149000},
    {display = "Shiny Star", key = "items:shiny_star", price = 799},
    {display = "Super Candy", key = "items:super_candy", price = 799},
    {display = "Incense", key = "items:incense", price = 5000},
    {display = "Meteorite", key = "items:meteorite", price = 5000},
    {display = "x2 Celestial Luck!", key = "items:x2_celestial_luck!", price = 1500000},
    -- Stones
    {display = "Dragon Evo Stone", key = "items:dragon_evolution_stone", price = 29},
    {display = "Grass Evo Stone", key = "items:grass_evolution_stone", price = 29},
    {display = "Ground Evo Stone", key = "items:ground_evolution_stone", price = 29},
    {display = "Normal Evo Stone", key = "items:normal_evolution_stone", price = 29},
    {display = "Poison Evo Stone", key = "items:poison_evolution_stone", price = 29},
    {display = "Rock Evo Stone", key = "items:rock_evolution_stone", price = 29},
    {display = "Water Evo Stone", key = "items:water_evolution_stone", price = 29},
    {display = "Psychic Evo Stone",key = "items:psychic_evolution_stone", price = 29},
    {display = "Fairy Evo Stone", key = "items:fairy_evolution_stone", price = 29},
    {display = "Bug Evo Stone", key = "items:bug_evolution_stone", price = 29},
    {display = "Ice Evo Stone", key = "items:ice_evolution_stone", price = 29},
    {display = "Dark Evo Stone", key = "items:dark_evolution_stone", price = 29},
    {display = "Steel Evo Stone", key = "items:steel_evolution_stone", price = 29},
    {display = "Electric Evo Stone", key = "items:electric_evolution_stone", price = 29},
    {display = "Fighting Evo Stone", key = "items:fighting_evolution_stone", price = 29},
    {display = "Fire Evo Stone", key = "items:fire_evolution_stone", price = 29},
    {display = "Flying Evo Stone", key = "items:flying_evolution_stone", price = 29},
    {display = "Ghost Evo Stone", key = "items:ghost_evolution_stone", price = 29},
}

-- Sort into categories
local Categories = { Potions = {}, Foods = {}, Stones = {} }
for _, item in ipairs(Items) do
    local name = item.display:lower()
    if name:find("potion") or name:find("luck") or name:find("candy") or name:find("incense") or name:find("meteorite") or name:find("star") then
        table.insert(Categories.Potions, item)
    elseif name:find("sandwich") or name:find("bubble gum") or name:find("cookies") or name:find("cake") or name:find("paella") or name:find("gyozas") then
        table.insert(Categories.Foods, item)
    elseif name:find("evo stone") or name:find("stone") then
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
        AutoBuyDelay = Config.AutoBuyDelay,
        InfiniteMagnet = Config.InfiniteMagnet,
        -- [NEW] Save Farming Configs
        FarmRange = Config.FarmRange,
        Farm1Enabled = Config.Farm1Enabled,
        Farm2Enabled = Config.Farm2Enabled
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
            Config.InfiniteMagnet = r.InfiniteMagnet or false
            
            -- [NEW] Load Farming Configs
            Config.FarmRange = r.FarmRange or 300
            Config.Farm1Enabled = r.Farm1Enabled or false
            Config.Farm2Enabled = r.Farm2Enabled or false
            
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
create("TextLabel", { Parent = TopBar, Text = " GLUM HUB", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C_TEXT, Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
local CloseBtn = create("TextButton", { Parent = TopBar, Text = "X", Font = Enum.Font.GothamBold, TextColor3 = C_RED, Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(1, -32, 0, 0), BackgroundTransparency = 1 })
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Tab Buttons
local TabContainer = create("Frame", { Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 0, 32), BackgroundColor3 = C_MAIN, Parent = MainFrame }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}) })
local MerchantBtn = create("TextButton", { Parent = TabContainer, Size = UDim2.new(0.333, 0, 1, 0), BackgroundTransparency = 1, Text = "Merchant", Font = Enum.Font.GothamMedium, TextColor3 = C_TEXT, TextSize = 13 })
local FarmingBtn = create("TextButton", { Parent = TabContainer, Size = UDim2.new(0.333, 0, 1, 0), Position = UDim2.new(0.333, 0, 0, 0), BackgroundTransparency = 1, Text = "Farming", Font = Enum.Font.GothamMedium, TextColor3 = C_TEXT_DIM, TextSize = 13 })
local ConfigBtn = create("TextButton", { Parent = TabContainer, Size = UDim2.new(0.333, 0, 1, 0), Position = UDim2.new(0.666, 0, 0, 0), BackgroundTransparency = 1, Text = "Config", Font = Enum.Font.GothamMedium, TextColor3 = C_TEXT_DIM, TextSize = 13 })
local Indicator = create("Frame", { Parent = TabContainer, Size = UDim2.new(0.333, -4, 0, 2), Position = UDim2.new(0, 2, 1, -2), BackgroundColor3 = C_GREEN, BorderSizePixel = 0 })

-- Pages
local PageContainer = create("Frame", { Size = UDim2.new(1, -16, 1, -74), Position = UDim2.new(0, 8, 0, 70), BackgroundTransparency = 1, Parent = MainFrame })
local MerchantPage = create("ScrollingFrame", { Parent = PageContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = C_ACCENT, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0) })
local FarmingPage = create("ScrollingFrame", { Parent = PageContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 2, ScrollBarImageColor3 = C_ACCENT })
local ConfigPage = create("ScrollingFrame", { Parent = PageContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 2, ScrollBarImageColor3 = C_ACCENT })

create("UIListLayout", { Parent = MerchantPage, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
create("UIPadding", { Parent = MerchantPage, PaddingRight = UDim.new(0, 4) })
create("UIListLayout", { Parent = FarmingPage, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
create("UIPadding", { Parent = FarmingPage, PaddingRight = UDim.new(0, 4) })
create("UIListLayout", { Parent = ConfigPage, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })

-- Switch Tabs
MerchantBtn.MouseButton1Click:Connect(function()
    MerchantPage.Visible = true; FarmingPage.Visible = false; ConfigPage.Visible = false
    MerchantBtn.TextColor3 = C_TEXT; FarmingBtn.TextColor3 = C_TEXT_DIM; ConfigBtn.TextColor3 = C_TEXT_DIM
    Indicator:TweenPosition(UDim2.new(0, 2, 1, -2), "Out", "Quad", 0.2)
end)
FarmingBtn.MouseButton1Click:Connect(function()
    MerchantPage.Visible = false; FarmingPage.Visible = true; ConfigPage.Visible = false
    MerchantBtn.TextColor3 = C_TEXT_DIM; FarmingBtn.TextColor3 = C_TEXT; ConfigBtn.TextColor3 = C_TEXT_DIM
    Indicator:TweenPosition(UDim2.new(0.333, 2, 1, -2), "Out", "Quad", 0.2)
end)
ConfigBtn.MouseButton1Click:Connect(function()
    MerchantPage.Visible = false; FarmingPage.Visible = false; ConfigPage.Visible = true
    MerchantBtn.TextColor3 = C_TEXT_DIM; FarmingBtn.TextColor3 = C_TEXT_DIM; ConfigBtn.TextColor3 = C_TEXT
    Indicator:TweenPosition(UDim2.new(0.666, 2, 1, -2), "Out", "Quad", 0.2)
end)

--== FARMING PAGE LOGIC ==--

-- 1. MAGNET SECTION (FIXED UI)
local MagnetPanel = create("Frame", { Parent = FarmingPage, Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C_MAIN }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}), create("UIStroke", {Color = C_ACCENT}) })

create("TextLabel", { Parent = MagnetPanel, Text = "Magnet Collection", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C_TEXT_DIM, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })

local MagnetBtn = create("TextButton", {
    Parent = MagnetPanel, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 28),
    BackgroundColor3 = C_ACCENT, Text = "Enable Infinite Magnet", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C_TEXT
}, { create("UICorner", {CornerRadius = UDim.new(0, 4)}) })

local magnetConnections = {}
local magnetListener = nil

local function SetMagnetState(state)
    Config.InfiniteMagnet = state
    if state then
        MagnetBtn.Text = "Magnet Active"
        MagnetBtn.TextColor3 = C_GREEN
        MagnetBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        local orbFolder = workspace:WaitForChild("Orbs")
        
        local function magnet(orb)
            if not Config.InfiniteMagnet then return end
            local part = orb:IsA("Model") and (orb.PrimaryPart or orb:FindFirstChildWhichIsA("BasePart")) or orb:IsA("BasePart") and orb
            if not part then return end
            part.Transparency = 1; part.CanCollide = false; part.CastShadow = false; part.Anchored = true
            
            local connection
            connection = RunService.Heartbeat:Connect(function()
                if not Config.InfiniteMagnet then if connection then connection:Disconnect() end return end
                if not part.Parent or not LocalPlayer.Character then connection:Disconnect() return end
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then part.CFrame = root.CFrame end
            end)
            table.insert(magnetConnections, connection)
        end
        for _, orb in pairs(orbFolder:GetChildren()) do magnet(orb) end
        magnetListener = orbFolder.ChildAdded:Connect(function(orb) task.wait(); if Config.InfiniteMagnet then magnet(orb) end end)
    else
        MagnetBtn.Text = "Enable Infinite Magnet"
        MagnetBtn.TextColor3 = C_TEXT
        MagnetBtn.BackgroundColor3 = C_ACCENT
        if magnetListener then magnetListener:Disconnect() magnetListener = nil end
        for _, conn in pairs(magnetConnections) do if conn then conn:Disconnect() end end
        magnetConnections = {}
    end
end
MagnetBtn.MouseButton1Click:Connect(function() SetMagnetState(not Config.InfiniteMagnet) end)
if Config.InfiniteMagnet then SetMagnetState(true) end

-- 2. RANGE SETTING
local RangePanel = create("Frame", { Parent = FarmingPage, Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C_MAIN }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}), create("UIStroke", {Color = C_ACCENT}) })
create("TextLabel", { Parent = RangePanel, Text = "Farm Range (50-400)", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C_TEXT_DIM, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })

local RangeInput = create("TextBox", {
    Parent = RangePanel, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 28),
    BackgroundColor3 = C_BG, Text = tostring(Config.FarmRange), TextColor3 = C_BLUE, Font = Enum.Font.Code, TextSize = 13
}, { create("UICorner", {CornerRadius = UDim.new(0, 4)}), create("UIStroke", {Color = C_ACCENT}) })

addTooltip(RangeInput, "Set the detection range for auto farming")

RangeInput.FocusLost:Connect(function()
    local n = tonumber(RangeInput.Text)
    if n then
        n = math.clamp(n, 50, 400)
        Config.FarmRange = n
    else
        Config.FarmRange = 300
    end
    RangeInput.Text = tostring(Config.FarmRange)
end)

-- 3. FARM TOGGLES (RENAMED)
local Farm1Btn = create("TextButton", {
    Parent = FarmingPage, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C_ACCENT,
    Text = "Single Farm (1 Pet/Coin)", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C_TEXT
}, { create("UICorner", {CornerRadius = UDim.new(0, 6)}) })
addTooltip(Farm1Btn, "Sends 3 pets to chests/balls, if none found then sends 1 pet to each different low tier breakable")

local Farm2Btn = create("TextButton", {
    Parent = FarmingPage, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C_ACCENT,
    Text = "Group Farm (ALL)", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C_TEXT
}, { create("UICorner", {CornerRadius = UDim.new(0, 6)}) })
addTooltip(Farm2Btn, "Sends ALL pets to the nearest breakable.")

local function updateFarmButtons()
    if Config.Farm1Enabled then
        Farm1Btn.Text = "Single Farm: ACTIVE"
        Farm1Btn.TextColor3 = C_GREEN
        Farm1Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    else
        Farm1Btn.Text = "Single Farm (1 Pet/Coin)"
        Farm1Btn.TextColor3 = C_TEXT
        Farm1Btn.BackgroundColor3 = C_ACCENT
    end

    if Config.Farm2Enabled then
        Farm2Btn.Text = "Group Farm: ACTIVE"
        Farm2Btn.TextColor3 = C_GREEN
        Farm2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    else
        Farm2Btn.Text = "Group Farm (ALL)"
        Farm2Btn.TextColor3 = C_TEXT
        Farm2Btn.BackgroundColor3 = C_ACCENT
    end
end

Farm1Btn.MouseButton1Click:Connect(function()
    Config.Farm1Enabled = not Config.Farm1Enabled
    if Config.Farm1Enabled then Config.Farm2Enabled = false end -- Disable other
    updateFarmButtons()
end)

Farm2Btn.MouseButton1Click:Connect(function()
    Config.Farm2Enabled = not Config.Farm2Enabled
    if Config.Farm2Enabled then Config.Farm1Enabled = false end -- Disable other
    updateFarmButtons()
end)

updateFarmButtons() -- Init state

--== MERCHANT PAGE LOGIC ==--
local function createCategory(name, items, order)
    local Wrapper = create("Frame", { Parent = MerchantPage, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C_MAIN, LayoutOrder = order, ClipsDescendants = true }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}), create("UIStroke", {Color = C_ACCENT}) })
    local Header = create("TextButton", { Parent = Wrapper, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = "", ZIndex = 2 })
    create("TextLabel", { Parent = Header, Text = name, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C_TEXT, Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left })
    local Arrow = create("TextLabel", { Parent = Header, Text = "+", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C_TEXT_DIM, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1 })
    
    local SelectAllBtn = create("TextButton", { Parent = Header, Size = UDim2.new(0, 60, 0, 20), Position = UDim2.new(1, -100, 0, 8), BackgroundColor3 = C_ACCENT, Text = "Select All", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C_TEXT, ZIndex = 3 }, { create("UICorner", {CornerRadius = UDim.new(0, 4)}) })
    addTooltip(SelectAllBtn, "Toggle all items in this category")

    local ItemContainer = create("Frame", { Parent = Wrapper, Size = UDim2.new(1, -16, 0, 0), Position = UDim2.new(0, 8, 0, 36), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
    local List = create("UIListLayout", { Parent = ItemContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
    local itemToggles = {}

    for _, item in ipairs(items) do
        local row = create("Frame", { Parent = ItemContainer, Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C_BG }, { create("UICorner", {CornerRadius = UDim.new(0, 4)}) })
        local check = create("TextButton", { Parent = row, Size = UDim2.new(0, 24, 0, 24), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C_GREEN })
        local box = create("Frame", { Parent = check, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0.5, -7, 0.5, -7), BackgroundColor3 = C_MAIN, BorderColor3 = C_TEXT_DIM, BorderSizePixel = 1 })
        
        local function updateCheck() box.BackgroundColor3 = Config.SelectedItems[item.key] and C_GREEN or C_MAIN end
        updateCheck()
        itemToggles[item.key] = updateCheck
        check.MouseButton1Click:Connect(function() Config.SelectedItems[item.key] = not Config.SelectedItems[item.key]; updateCheck() end)
        create("TextLabel", { Parent = row, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 30, 0, 0), BackgroundTransparency = 1, Text = item.display .. " [$" .. item.price .. "]", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C_TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Left })
    end

    SelectAllBtn.MouseButton1Click:Connect(function()
        local allSelected = true
        for _, item in ipairs(items) do if not Config.SelectedItems[item.key] then allSelected = false break end end
        for _, item in ipairs(items) do Config.SelectedItems[item.key] = not allSelected; if itemToggles[item.key] then itemToggles[item.key]() end end
    end)

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

local AutoBuyPanel = create("Frame", { Parent = MerchantPage, LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C_MAIN }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}), create("UIStroke", {Color = C_ACCENT}) })
local ToggleBtn = create("TextButton", { Parent = AutoBuyPanel, Size = UDim2.new(0, 120, 0, 32), Position = UDim2.new(0, 12, 0, 14), BackgroundColor3 = C_RED, Text = "AUTO BUY: OFF", Font = Enum.Font.GothamBold, TextColor3 = C_TEXT, TextSize = 12 }, { create("UICorner", {CornerRadius = UDim.new(0, 4)}) })
local function updateMasterToggle() ToggleBtn.Text = "AUTO BUY: " .. (Config.AutoBuyEnabled and "ON" or "OFF"); ToggleBtn.BackgroundColor3 = Config.AutoBuyEnabled and C_GREEN or C_RED end
updateMasterToggle()
ToggleBtn.MouseButton1Click:Connect(function() Config.AutoBuyEnabled = not Config.AutoBuyEnabled; updateMasterToggle() end)

local DelayInput = create("TextBox", { Parent = AutoBuyPanel, Size = UDim2.new(0, 50, 0, 30), Position = UDim2.new(1, -62, 0, 15), BackgroundColor3 = C_BG, Text = tostring(Config.AutoBuyDelay), TextColor3 = C_TEXT, Font = Enum.Font.Gotham, TextSize = 12 }, { create("UICorner", {CornerRadius = UDim.new(0, 4)}), create("UIStroke", {Color = C_ACCENT}) })
create("TextLabel", { Parent = AutoBuyPanel, Text = "Delay (s):", Position = UDim2.new(1, -130, 0, 15), Size = UDim2.new(0, 60, 0, 30), BackgroundTransparency = 1, TextColor3 = C_TEXT_DIM, Font = Enum.Font.Gotham, TextSize = 12 })
DelayInput.FocusLost:Connect(function() local n = tonumber(DelayInput.Text); if n then Config.AutoBuyDelay = n else DelayInput.Text = tostring(Config.AutoBuyDelay) end end)

--== CONFIG PAGE LOGIC ==--
local StatusLabel = create("TextLabel", { Parent = ConfigPage, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Current Config: " .. Config.ConfigName, TextColor3 = C_GREEN, Font = Enum.Font.Code, TextSize = 12 })
local AutoLoadLabel = create("TextLabel", { Parent = ConfigPage, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Auto-Load: " .. (Settings.AutoLoadEnabled and Settings.AutoLoadConfigName or "Disabled"), TextColor3 = C_BLUE, Font = Enum.Font.Code, TextSize = 12 })

local function updateInfo()
    StatusLabel.Text = "Current Config: " .. Config.ConfigName
    AutoLoadLabel.Text = "Auto-Load: " .. (Settings.AutoLoadEnabled and Settings.AutoLoadConfigName or "Disabled")
    -- Update farm UI elements when config is loaded
    RangeInput.Text = tostring(Config.FarmRange)
    updateFarmButtons()
end

local NameInput = create("TextBox", { Parent = ConfigPage, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C_MAIN, PlaceholderText = "Enter config name...", Text = "", TextColor3 = C_TEXT, Font = Enum.Font.Gotham, TextSize = 13 }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}), create("UIStroke", {Color = C_ACCENT}) })
local SaveBtn = create("TextButton", { Parent = ConfigPage, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C_ACCENT, Text = "Save Current Settings", Font = Enum.Font.GothamBold, TextColor3 = C_TEXT, TextSize = 13 }, { create("UICorner", {CornerRadius = UDim.new(0, 6)}) })
local ConfigListFrame = create("Frame", { Parent = ConfigPage, LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y })
local RefreshBtn = create("TextButton", { Parent = ConfigPage, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "Refresh Config List", TextColor3 = C_TEXT_DIM, Font = Enum.Font.Gotham, TextSize = 12 })

local function refreshConfigList()
    ConfigListFrame:ClearAllChildren()
    create("UIListLayout", { Parent = ConfigListFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
    for _, fname in ipairs(listConfigs()) do
        local row = create("Frame", { Parent = ConfigListFrame, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C_MAIN }, { create("UICorner", {CornerRadius = UDim.new(0, 4)}) })
        local loadB = create("TextButton", { Parent = row, Size = UDim2.new(1, -120, 1, 0), BackgroundTransparency = 1, Text = " " .. fname, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C_TEXT, Font = Enum.Font.Gotham, TextSize = 13 })
        loadB.MouseButton1Click:Connect(function() if loadConfig(fname) then updateInfo(); NameInput.Text = fname; DelayInput.Text = tostring(Config.AutoBuyDelay); updateMasterToggle() end end)
        local mainB = create("TextButton", { Parent = row, Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -90, 0, 0), BackgroundColor3 = C_BLUE, Text = "Main", TextColor3 = C_TEXT, Font = Enum.Font.GothamBold, TextSize = 10 })
        mainB.MouseButton1Click:Connect(function() Settings.AutoLoadConfigName = fname; Settings.AutoLoadEnabled = true; saveMainSettings(); updateInfo() end)
        local delB = create("TextButton", { Parent = row, Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -30, 0, 0), BackgroundColor3 = C_RED, Text = "X", TextColor3 = C_TEXT, Font = Enum.Font.GothamBold, TextSize = 12 })
        delB.MouseButton1Click:Connect(function() deleteConfig(fname); refreshConfigList() end)
    end
end

SaveBtn.MouseButton1Click:Connect(function() local n = NameInput.Text; if n == "" then n = Config.ConfigName end; saveConfig(n); updateInfo(); task.wait(0.1); refreshConfigList() end)
RefreshBtn.MouseButton1Click:Connect(refreshConfigList)
refreshConfigList()
updateInfo()

--== MAIN LOOPS ==--

-- Merchant Auto-Buy Loop
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

-- Advanced Farming Loop (Single & Group)
task.spawn(function()
    -- Safely grab game modules
    local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
    local Source = PlayerScripts:WaitForChild("Source")
    local WorldManager = require(Source:WaitForChild("ClientWorldManager"))
    local ClientPlayerManager = require(Source:WaitForChild("ClientPlayerManager"))
    local EventHandler = require(ReplicatedStorage.Common.EventHandler)

    local HighPriority = {"chest", "petball", "super_candy", "crystal"}

    print(">> Farming Logic Loaded")

    while ScreenGui.Parent do
        task.wait(0.2)
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        
        -- === FARM 1: SINGLE FARM (PACKET) ===
        if Config.Farm1Enabled and Root then
             -- 1. GET FREE PETS
            local MyData = ClientPlayerManager:get_player_data(LocalPlayer)
            local FreePets = {}
            if MyData and MyData.entities then
                for id, pet in pairs(MyData.entities) do
                    if pet.task == "idle" then
                        table.insert(FreePets, id)
                    end
                end
            end
            
            if #FreePets > 0 then
                local MyPos = Root.Position
                local Chests = {}
                local Others = {}
                local Range = Config.FarmRange or 300

                -- 2. SCAN & SORT
                for id, farmeable in pairs(WorldManager.farmeables) do
                    if farmeable and farmeable.position then
                        local Dist = (farmeable.position - MyPos).Magnitude
                        if Dist < Range then
                            local Type = "unknown"
                            if farmeable.render then
                                if typeof(farmeable.render.instance) == "Instance" then Type = farmeable.render.instance.Name
                                elseif type(farmeable.render.instance) == "string" then Type = farmeable.render.instance
                                elseif type(farmeable.render.name) == "string" then Type = farmeable.render.name end
                            end
                            Type = string.lower(Type)
                            
                            local Data = {id=id, dist=Dist}
                            local IsPriority = false
                            for _, k in pairs(HighPriority) do
                                if string.find(Type, k) then IsPriority = true break end
                            end
                            
                            if IsPriority then table.insert(Chests, Data) else table.insert(Others, Data) end
                        end
                    end
                end
                
                table.sort(Chests, function(a,b) return a.dist < b.dist end)
                table.sort(Others, function(a,b) return a.dist < b.dist end)
                
                -- 3. ASSIGN TASKS
                local Tasks = {}
                
                if #Chests > 0 then
                    -- CHEST MODE: All free pets go to ONE chest
                    local Target = Chests[1].id
                    for _, petID in pairs(FreePets) do
                        Tasks[petID] = { ["task"] = "farm", ["target_id"] = Target }
                    end
                else
                    -- COIN MODE: 1 Pet per Coin
                    local CoinIndex = 1
                    for _, petID in pairs(FreePets) do
                        if Others[CoinIndex] then
                            local Target = Others[CoinIndex].id
                            Tasks[petID] = { ["task"] = "farm", ["target_id"] = Target }
                            CoinIndex = CoinIndex + 1
                        else
                            break
                        end
                    end
                end
                
                -- 4. SEND PACKET
                if next(Tasks) then
                    EventHandler:send("SET_PETS_TASKS", Tasks)
                end
            end
            
        -- === FARM 2: GROUP FARM (WOLF PACK) ===
        elseif Config.Farm2Enabled and Root then
            if WorldManager:count_free_pets() > 0 then
                local MyPos = Root.Position
                local Range = Config.FarmRange or 300
                
                local BestPriorityID = nil
                local BestPriorityDist = Range
                local BestFillerID = nil
                local BestFillerDist = Range

                for id, farmeable in pairs(WorldManager.farmeables) do
                    if farmeable and farmeable.position then
                        local Dist = (farmeable.position - MyPos).Magnitude
                        
                        if Dist < Range then
                            local Type = "unknown"
                            if farmeable.render then
                                if typeof(farmeable.render.instance) == "Instance" then Type = farmeable.render.instance.Name
                                elseif type(farmeable.render.instance) == "string" then Type = farmeable.render.instance
                                elseif type(farmeable.render.name) == "string" then Type = farmeable.render.name end
                            end
                            Type = string.lower(Type)
                            
                            local IsPriority = false
                            for _, k in pairs(HighPriority) do
                                if string.find(Type, k) then IsPriority = true break end
                            end
                            
                            if IsPriority then
                                if Dist < BestPriorityDist then
                                    BestPriorityDist = Dist
                                    BestPriorityID = id
                                end
                            else
                                if Dist < BestFillerDist then
                                    BestFillerDist = Dist
                                    BestFillerID = id
                                end
                            end
                        end
                    end
                end

                local FinalTarget = BestPriorityID or BestFillerID
                if FinalTarget then
                    WorldManager:send_farm(FinalTarget, false)
                end
            end
        end
    end
end)
