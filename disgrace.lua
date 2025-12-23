--// Dark VSCode‑style Merchant GUI (with categories)
--// Put in a LocalScript (executor) while in game

--== SETTINGS ==--
local CONFIG_FILE = "MerchantGUI_Config.json"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local PurchaseRemote = ReplicatedStorage:WaitForChild("NetworkEvents"):WaitForChild("PURCHASE_SHOP_STOCK")

--== ITEM LIST (name in GUI, remoteKey, price) ==--
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

--== CONFIG STATE ==--
local Config = {
    SelectedItemIndex = 1,
    AutoBuyEnabled = false,
    AutoLoadOnExecute = true,
    AutoBuyDelay = 1
}

--== UTIL: load/save ==--
local function loadConfig()
    if not isfile or not pcall(isfile, CONFIG_FILE) then return end
    local ok, data = pcall(readfile, CONFIG_FILE)
    if not ok then return end
    local dec
    pcall(function()
        dec = HttpService:JSONDecode(data)
    end)
    if type(dec) == "table" then
        for k,v in pairs(dec) do
            Config[k] = v
        end
    end
end

local function saveConfig()
    if not writefile then return end
    local data = HttpService:JSONEncode(Config)
    writefile(CONFIG_FILE, data)
end

-- Auto-load
if Config.AutoLoadOnExecute then
    loadConfig()
end

--== SMALL UI HELPER ==--
local function createInstance(class, props)
    local inst = Instance.new(class)
    for k,v in pairs(props) do
        inst[k] = v
    end
    return inst
end

--== SCREEN + WINDOW ==--
local ScreenGui = createInstance("ScreenGui", {
    Name = "DarkMerchantGUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = LocalPlayer:WaitForChild("PlayerGui")
})

local MainFrame = createInstance("Frame", {
    Name = "MainFrame",
    Parent = ScreenGui,
    Size = UDim2.new(0, 450, 0, 260),
    Position = UDim2.new(0.5, -225, 0.5, -130),
    BackgroundColor3 = Color3.fromRGB(24, 24, 27),
    BorderSizePixel = 0
})

-- Draggable
local dragToggle, dragStart, startPos
local UserInputService = game:GetService("UserInputService")

local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragToggle = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragToggle and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateDrag(input)
    end
end)

-- Top bar
local TopBar = createInstance("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = Color3.fromRGB(17, 17, 20),
    BorderSizePixel = 0
})

local Title = createInstance("TextLabel", {
    Parent = TopBar,
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Merchant Utility",
    Font = Enum.Font.Code,
    TextColor3 = Color3.fromRGB(200, 200, 200),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextSize = 16
})

local CloseButton = createInstance("TextButton", {
    Parent = TopBar,
    Size = UDim2.new(0, 40, 1, 0),
    Position = UDim2.new(1, -40, 0, 0),
    BackgroundTransparency = 1,
    Text = "X",
    Font = Enum.Font.Code,
    TextColor3 = Color3.fromRGB(220, 80, 80),
    TextSize = 16
})
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Tabs
local TabBar = createInstance("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 0, 26),
    Position = UDim2.new(0, 0, 0, 28),
    BackgroundColor3 = Color3.fromRGB(30, 30, 36),
    BorderSizePixel = 0
})

local function createTabButton(name, xPos)
    return createInstance("TextButton", {
        Parent = TabBar,
        Size = UDim2.new(0, 90, 1, 0),
        Position = UDim2.new(0, xPos, 0, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 36),
        BorderSizePixel = 0,
        Text = name,
        Font = Enum.Font.Code,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(160, 160, 170)
    })
end

local MerchantTabButton = createTabButton("Merchant", 4)
local ConfigTabButton   = createTabButton("Config",   98)

local ContentFrame = createInstance("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, -8, 1, -62),
    Position = UDim2.new(0, 4, 0, 54),
    BackgroundColor3 = Color3.fromRGB(18, 18, 24),
    BorderSizePixel = 0
})

local MerchantPage = createInstance("Frame", {
    Parent = ContentFrame,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0)
})

local ConfigPage = createInstance("Frame", {
    Parent = ContentFrame,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Visible = false
})

local function setActiveTab(tabName)
    if tabName == "Merchant" then
        MerchantPage.Visible = true
        ConfigPage.Visible = false
        MerchantTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        ConfigTabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    else
        MerchantPage.Visible = false
        ConfigPage.Visible = true
        MerchantTabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        ConfigTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    end
end

MerchantTabButton.MouseButton1Click:Connect(function()
    setActiveTab("Merchant")
end)
ConfigTabButton.MouseButton1Click:Connect(function()
    setActiveTab("Config")
end)

--========================================================
--== MERCHANT PAGE WITH CATEGORIES =======================
--========================================================

-- categorize items
local Potions, Foods, Stones = {}, {}, {}

for _, item in ipairs(Items) do
    local name = item.display:lower()
    if name:find("potion") or name:find("luck") or name:find("candy") or name:find("incense") or name:find("meteorite") or name:find("star") then
        table.insert(Potions, item)
    elseif name:find("sandwich") or name:find("bubble gum") or name:find("cookies") or name:find("cake") or name:find("paella") or name:find("gyozas") then
        table.insert(Foods, item)
    elseif name:find("evolution stone") or name:find("stone") then
        table.insert(Stones, item)
    else
        table.insert(Potions, item)
    end
end

local function createCategoryDropdown(parent, titleText, posY, list)
    local group = {}

    group.Label = createInstance("TextLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, posY),
        Size = UDim2.new(0, 200, 0, 18),
        Text = titleText,
        Font = Enum.Font.Code,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    group.Button = createInstance("TextButton", {
        Parent = parent,
        Position = UDim2.new(0, 8, 0, posY + 20),
        Size = UDim2.new(0, 260, 0, 24),
        BackgroundColor3 = Color3.fromRGB(32, 32, 40),
        BorderColor3 = Color3.fromRGB(60, 60, 80),
        Text = "",
        Font = Enum.Font.Code,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    group.Text = createInstance("TextLabel", {
        Parent = group.Button,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 6, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Enum.Font.Code,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        Text = (list[1] and (list[1].display .. " | " .. list[1].price .. " gold")) or "None"
    })

    group.Arrow = createInstance("TextLabel", {
        Parent = group.Button,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -18, 0, 0),
        Size = UDim2.new(0, 18, 1, 0),
        Font = Enum.Font.Code,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Text = "▼"
    })

    group.Frame = createInstance("Frame", {
        Parent = parent,
        BackgroundColor3 = Color3.fromRGB(24, 24, 32),
        BorderColor3 = Color3.fromRGB(60, 60, 80),
        Position = UDim2.new(0, 8, 0, posY + 44),
        Size = UDim2.new(0, 260, 0, 120),
        Visible = false
    })

    local layout = Instance.new("UIListLayout", group.Frame)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 1)

    for _, item in ipairs(list) do
        local btn = createInstance("TextButton", {
            Parent = group.Frame,
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundColor3 = Color3.fromRGB(32, 32, 40),
            BorderSizePixel = 0,
            Text = string.format("%s  |  %d", item.display, item.price),
            Font = Enum.Font.Code,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(210, 210, 210),
            TextXAlignment = Enum.TextXAlignment.Left
        })

        btn.MouseButton1Click:Connect(function()
            group.Text.Text = string.format("%s  |  %d gold", item.display, item.price)
            group.Frame.Visible = false

            -- update global SelectedItemIndex so autobuy uses last chosen
            for idx, fullItem in ipairs(Items) do
                if fullItem.key == item.key then
                    Config.SelectedItemIndex = idx
                    break
                end
            end
        end)

        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
        end)
    end

    group.Button.MouseButton1Click:Connect(function()
        group.Frame.Visible = not group.Frame.Visible
    end)

    return group
end

-- clear in case something was auto-added
MerchantPage:ClearAllChildren()

local PotionsDrop = createCategoryDropdown(MerchantPage, "Potions / Utility:", 8, Potions)
local FoodsDrop   = createCategoryDropdown(MerchantPage, "Foods:",             80, Foods)
local StonesDrop  = createCategoryDropdown(MerchantPage, "Evolution Stones:",  152, Stones)

-- Auto buy toggle + delay
local AutoBuyToggle = createInstance("TextButton", {
    Parent = MerchantPage,
    Position = UDim2.new(0, 8, 0, 210),
    Size = UDim2.new(0, 120, 0, 24),
    BackgroundColor3 = Color3.fromRGB(40, 40, 52),
    BorderColor3 = Color3.fromRGB(70, 70, 90),
    Text = "",
    Font = Enum.Font.Code,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(220, 220, 220),
    TextXAlignment = Enum.TextXAlignment.Center
})

local function updateAutoBuyButton()
    AutoBuyToggle.Text = "Auto Buy: " .. (Config.AutoBuyEnabled and "ON" or "OFF")
    AutoBuyToggle.TextColor3 = Config.AutoBuyEnabled
        and Color3.fromRGB(120, 220, 120)
        or  Color3.fromRGB(220, 120, 120)
end
updateAutoBuyButton()

AutoBuyToggle.MouseButton1Click:Connect(function()
    Config.AutoBuyEnabled = not Config.AutoBuyEnabled
    updateAutoBuyButton()
end)

local DelayLabel = createInstance("TextLabel", {
    Parent = MerchantPage,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 160, 0, 210),
    Size = UDim2.new(0, 120, 0, 24),
    Text = "Delay (s):",
    Font = Enum.Font.Code,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(200, 200, 200),
    TextXAlignment = Enum.TextXAlignment.Left
})

local DelayBox = createInstance("TextBox", {
    Parent = MerchantPage,
    Position = UDim2.new(0, 230, 0, 210),
    Size = UDim2.new(0, 60, 0, 22),
    BackgroundColor3 = Color3.fromRGB(32, 32, 40),
    BorderColor3 = Color3.fromRGB(60, 60, 80),
    Text = tostring(Config.AutoBuyDelay),
    Font = Enum.Font.Code,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(220, 220, 220),
    ClearTextOnFocus = false
})

DelayBox.FocusLost:Connect(function()
    local n = tonumber(DelayBox.Text)
    if n and n > 0 then
        Config.AutoBuyDelay = n
    else
        DelayBox.Text = tostring(Config.AutoBuyDelay)
    end
end)

--========================================================
--== AUTOBUY LOOP =======================================
--========================================================

task.spawn(function()
    while ScreenGui.Parent do
        if Config.AutoBuyEnabled then
            local item = Items[Config.SelectedItemIndex]
            if item then
                local args = {item.key, 1}
                pcall(function()
                    PurchaseRemote:InvokeServer(unpack(args))
                end)
            end
            task.wait(Config.AutoBuyDelay)
        else
            task.wait(0.2)
        end
    end
end)

--========================================================
--== CONFIG PAGE ========================================
--========================================================

local AutoLoadLabel = createInstance("TextLabel", {
    Parent = ConfigPage,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 12),
    Size = UDim2.new(0, 200, 0, 20),
    Text = "Auto-load config on execute:",
    Font = Enum.Font.Code,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(200, 200, 200),
    TextXAlignment = Enum.TextXAlignment.Left
})

local AutoLoadToggle = createInstance("TextButton", {
    Parent = ConfigPage,
    Position = UDim2.new(0, 220, 0, 10),
    Size = UDim2.new(0, 80, 0, 24),
    BackgroundColor3 = Color3.fromRGB(40, 40, 52),
    BorderColor3 = Color3.fromRGB(70, 70, 90),
    Text = "",
    Font = Enum.Font.Code,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(220, 220, 220)
})

local function updateAutoLoadButton()
    AutoLoadToggle.Text = Config.AutoLoadOnExecute and "ENABLED" or "DISABLED"
    AutoLoadToggle.TextColor3 = Config.AutoLoadOnExecute
        and Color3.fromRGB(120, 220, 120)
        or  Color3.fromRGB(220, 120, 120)
end
updateAutoLoadButton()

AutoLoadToggle.MouseButton1Click:Connect(function()
    Config.AutoLoadOnExecute = not Config.AutoLoadOnExecute
    updateAutoLoadButton()
end)

local SaveButton = createInstance("TextButton", {
    Parent = ConfigPage,
    Position = UDim2.new(0, 8, 0, 60),
    Size = UDim2.new(0, 160, 0, 26),
    BackgroundColor3 = Color3.fromRGB(40, 40, 52),
    BorderColor3 = Color3.fromRGB(70, 70, 90),
    Font = Enum.Font.Code,
    TextSize = 14,
    Text = "Save current config",
    TextColor3 = Color3.fromRGB(220, 220, 220)
})

local StatusLabel = createInstance("TextLabel", {
    Parent = ConfigPage,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 96),
    Size = UDim2.new(1, -16, 0, 20),
    Text = "",
    Font = Enum.Font.Code,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(150, 200, 150),
    TextXAlignment = Enum.TextXAlignment.Left
})

SaveButton.MouseButton1Click:Connect(function()
    saveConfig()
    StatusLabel.Text = "Config saved to " .. CONFIG_FILE
    task.delay(2, function()
        if StatusLabel then
            StatusLabel.Text = ""
        end
    end)
end)
