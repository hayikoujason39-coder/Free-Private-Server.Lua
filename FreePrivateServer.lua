-- ⚡ Private Server HUB v2.0 by ADMC
-- ✅ Features: Modern UI, Favorites, History, Categories, Settings, Notifications, Anti-AFK, Auto-Rejoin

-- === Configuration ===
local Config = {
    Version = "2.0",
    ToggleKey = Enum.KeyCode.F9,
    Theme = "Dark",
    AutoRejoin = true,
    AntiAFK = true,
    Notifications = true,
    SavePath = "PrivateServerHUB_v2/"
}

-- === Services ===
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local RobloxReplicatedStorage = game:GetService("RobloxReplicatedStorage")

-- === Core Crypto Functions (MD5 + HMAC + Base64) ===
local t={0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,0x6b901122,0xfd987193,0xa679438e,0x49b40821,0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391}

local function md5(m)
    local a,b,c,d=0x67452301,0xefcdab89,0x98badcfe,0x10325476
    local p=m.."\128"
    while #p%64~=56 do p=p.."\0" end
    local l=#m*8
    for i=0,7 do p=p..string.char(bit32.band(bit32.rshift(l,i*8),0xFF)) end
    for i=1,#p,64 do
        local ch=p:sub(i,i+63)
        local x={}
        for j=0,15 do
            local b1,b2,b3,b4=ch:byte(j*4+1,j*4+4)
            x[j]=bit32.bor(b1,bit32.lshift(b2,8),bit32.lshift(b3,16),bit32.lshift(b4,24))
        end
        local aa,bb,cc,dd=a,b,c,d
        local s={7,12,17,22,5,9,14,20,4,11,16,23,6,10,15,21}
        for j=0,63 do
            local f,k,si
            if j<16 then f=bit32.bor(bit32.band(b,c),bit32.band(bit32.bnot(b),d)) k=j si=j%4
            elseif j<32 then f=bit32.bor(bit32.band(b,d),bit32.band(c,bit32.bnot(d))) k=(1+5*j)%16 si=4+(j%4)
            elseif j<48 then f=bit32.bxor(b,bit32.bxor(c,d)) k=(5+3*j)%16 si=8+(j%4)
            else f=bit32.bxor(c,bit32.bor(b,bit32.bnot(d))) k=(7*j)%16 si=12+(j%4) end
            local tmp=bit32.band(a+f+x[k]+t[j+1],0xFFFFFFFF)
            tmp=bit32.bor(bit32.lshift(tmp,s[si+1]),bit32.rshift(tmp,32-s[si+1]))
            local nb=bit32.band(b+tmp,0xFFFFFFFF)
            a,b,c,d=d,nb,b,c
        end
        a=bit32.band(a+aa,0xFFFFFFFF)
        b=bit32.band(b+bb,0xFFFFFFFF)
        c=bit32.band(c+cc,0xFFFFFFFF)
        d=bit32.band(d+dd,0xFFFFFFFF)
    end
    local r=""
    for _,n in pairs{a,b,c,d}do
        for i=0,3 do r=r..string.char(bit32.band(bit32.rshift(n,i*8),0xFF)) end
    end
    return r
end

local function hmac(k,m,hf)
    if #k>64 then k=hf(k) end
    local okp,ikp="",""
    for i=1,64 do
        local by=(i<=#k and string.byte(k,i))or 0
        okp=okp..string.char(bit32.bxor(by,0x5C))
        ikp=ikp..string.char(bit32.bxor(by,0x36))
    end
    return hf(okp..hf(ikp..m))
end

local function base64(dt)
    local b="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    return((dt:gsub(".",function(x)
        local r,bv="",x:byte()
        for i=8,1,-1 do r=r..(bv%2^i-bv%2^(i-1)>0 and"1"or"0") end
        return r
    end).."0000"):gsub("%d%d%d?%d?%d?%d?",function(x)
        if#x<6 then return"" end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=="1"and 2^(6-i)or 0) end
        return b:sub(c+1,c+1)
    end)..({"","==","="})[#dt%3+1])
end

local function generateCode(pid)
    local u={}
    for i=1,16 do u[i]=math.random(0,255) end
    u[7]=bit32.bor(bit32.band(u[7],0x0F),0x40)
    u[9]=bit32.bor(bit32.band(u[9],0x3F),0x80)
    local fb=""
    for i=1,16 do fb=fb..string.char(u[i]) end
    local pib=""
    local pr=pid
    for _=1,8 do
        pib=pib..string.char(pr%256)
        pr=math.floor(pr/256)
    end
    local ct=fb..pib
    local sig=hmac("e4Yn8ckbCJtw2sv7qmbg",ct,md5)
    local acb=sig..ct
    local ac=base64(acb):gsub("+","-"):gsub("/","_")
    local pd=0
    ac=ac:gsub("=",function()pd=pd+1 return""end)
    ac=ac..tostring(pd)
    return ac
end

-- === Theme Colors ===
local Themes = {
    Dark = {
        Primary = Color3.fromRGB(25, 25, 35),
        Secondary = Color3.fromRGB(35, 35, 50),
        Tertiary = Color3.fromRGB(45, 45, 65),
        Accent = Color3.fromRGB(88, 101, 242),
        AccentHover = Color3.fromRGB(71, 82, 196),
        Success = Color3.fromRGB(87, 242, 135),
        Warning = Color3.fromRGB(254, 231, 92),
        Error = Color3.fromRGB(237, 66, 69),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(185, 185, 195),
        Border = Color3.fromRGB(60, 60, 80)
    },
    Light = {
        Primary = Color3.fromRGB(255, 255, 255),
        Secondary = Color3.fromRGB(245, 245, 250),
        Tertiary = Color3.fromRGB(235, 235, 245),
        Accent = Color3.fromRGB(88, 101, 242),
        AccentHover = Color3.fromRGB(71, 82, 196),
        Success = Color3.fromRGB(35, 165, 90),
        Warning = Color3.fromRGB(245, 165, 35),
        Error = Color3.fromRGB(220, 53, 69),
        Text = Color3.fromRGB(30, 30, 40),
        TextDim = Color3.fromRGB(100, 100, 120),
        Border = Color3.fromRGB(200, 200, 210)
    },
    Midnight = {
        Primary = Color3.fromRGB(15, 15, 25),
        Secondary = Color3.fromRGB(22, 22, 35),
        Tertiary = Color3.fromRGB(30, 30, 45),
        Accent = Color3.fromRGB(138, 43, 226),
        AccentHover = Color3.fromRGB(148, 0, 211),
        Success = Color3.fromRGB(0, 255, 127),
        Warning = Color3.fromRGB(255, 215, 0),
        Error = Color3.fromRGB(255, 69, 58),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(160, 160, 180),
        Border = Color3.fromRGB(50, 50, 70)
    },
    Ocean = {
        Primary = Color3.fromRGB(15, 32, 50),
        Secondary = Color3.fromRGB(20, 45, 70),
        Tertiary = Color3.fromRGB(25, 55, 85),
        Accent = Color3.fromRGB(0, 191, 255),
        AccentHover = Color3.fromRGB(0, 150, 200),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(170, 190, 210),
        Border = Color3.fromRGB(40, 75, 110)
    }
}

local CurrentTheme = Themes[Config.Theme]

-- === Data Management ===
local Data = {
    Favorites = {},
    History = {},
    Categories = {"Default", "Simulators", "FPS", "RPG", "Other"},
    Settings = {
        Theme = "Dark",
        AutoRejoin = true,
        AntiAFK = true,
        Notifications = true,
        MaxHistory = 20
    }
}

-- File System Functions
local function ensureFolder()
    if isfolder and not isfolder(Config.SavePath) then
        makefolder(Config.SavePath)
    end
end

local function loadData()
    ensureFolder()
    if isfile and isfile(Config.SavePath.."data.json") then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(Config.SavePath.."data.json"))
        end)
        if success and type(decoded) == "table" then
            Data.Favorites = decoded.Favorites or {}
            Data.History = decoded.History or {}
            Data.Categories = decoded.Categories or Data.Categories
            Data.Settings = decoded.Settings or Data.Settings
            Config.Theme = Data.Settings.Theme
            CurrentTheme = Themes[Config.Theme] or Themes.Dark
        end
    end
end

local function saveData()
    ensureFolder()
    if writefile then
        local success = pcall(function()
            writefile(Config.SavePath.."data.json", HttpService:JSONEncode(Data))
        end)
    end
end

loadData()

-- === Utility Functions ===
local function tween(obj, props, duration, style, direction)
    local tweenInfo = TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, tweenInfo, props)
    tw:Play()
    return tw
end

local function getGameName(placeId)
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(placeId)
    end)
    if success and info then
        return info.Name
    end
    return "Unknown Game"
end

local function formatNumber(n)
    return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function addToHistory(placeId, name)
    table.insert(Data.History, 1, {
        PlaceId = placeId,
        Name = name,
        Time = os.time()
    })
    if #Data.History > Data.Settings.MaxHistory then
        table.remove(Data.History)
    end
    saveData()
end

-- === GUI Creation ===
-- Remove existing GUI if present
if CoreGui:FindFirstChild("PrivateServerHUB_v2") then
    CoreGui:FindFirstChild("PrivateServerHUB_v2"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PrivateServerHUB_v2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Notification Container
local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "Notifications"
NotificationHolder.Size = UDim2.new(0, 300, 1, 0)
NotificationHolder.Position = UDim2.new(1, -320, 0, 0)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = ScreenGui

local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.Padding = UDim.new(0, 10)
NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotificationLayout.Parent = NotificationHolder

local NotificationPadding = Instance.new("UIPadding")
NotificationPadding.PaddingBottom = UDim.new(0, 20)
NotificationPadding.Parent = NotificationHolder

-- Notification Function
local function notify(title, message, notifType, duration)
    if not Data.Settings.Notifications then return end
    
    notifType = notifType or "Info"
    duration = duration or 3
    
    local colors = {
        Info = CurrentTheme.Accent,
        Success = CurrentTheme.Success,
        Warning = CurrentTheme.Warning,
        Error = CurrentTheme.Error
    }
    
    local icons = {
        Info = "ℹ️",
        Success = "✅",
        Warning = "⚠️",
        Error = "❌"
    }
    
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(1, 0, 0, 70)
    Notif.Position = UDim2.new(1, 50, 0, 0)
    Notif.BackgroundColor3 = CurrentTheme.Secondary
    Notif.BorderSizePixel = 0
    Notif.ClipsDescendants = true
    Notif.Parent = NotificationHolder
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 8)
    NotifCorner.Parent = Notif
    
    local NotifStroke = Instance.new("UIStroke")
    NotifStroke.Color = CurrentTheme.Border
    NotifStroke.Thickness = 1
    NotifStroke.Parent = Notif
    
    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 4, 1, 0)
    AccentBar.BackgroundColor3 = colors[notifType]
    AccentBar.BorderSizePixel = 0
    AccentBar.Parent = Notif
    
    local NotifTitle = Instance.new("TextLabel")
    NotifTitle.Size = UDim2.new(1, -50, 0, 25)
    NotifTitle.Position = UDim2.new(0, 15, 0, 8)
    NotifTitle.BackgroundTransparency = 1
    NotifTitle.Text = icons[notifType].." "..title
    NotifTitle.TextColor3 = CurrentTheme.Text
    NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
    NotifTitle.Font = Enum.Font.GothamBold
    NotifTitle.TextSize = 14
    NotifTitle.Parent = Notif
    
    local NotifMessage = Instance.new("TextLabel")
    NotifMessage.Size = UDim2.new(1, -30, 0, 30)
    NotifMessage.Position = UDim2.new(0, 15, 0, 32)
    NotifMessage.BackgroundTransparency = 1
    NotifMessage.Text = message
    NotifMessage.TextColor3 = CurrentTheme.TextDim
    NotifMessage.TextXAlignment = Enum.TextXAlignment.Left
    NotifMessage.Font = Enum.Font.Gotham
    NotifMessage.TextSize = 12
    NotifMessage.TextWrapped = true
    NotifMessage.Parent = Notif
    
    local CloseNotif = Instance.new("TextButton")
    CloseNotif.Size = UDim2.new(0, 25, 0, 25)
    CloseNotif.Position = UDim2.new(1, -30, 0, 5)
    CloseNotif.BackgroundTransparency = 1
    CloseNotif.Text = "✕"
    CloseNotif.TextColor3 = CurrentTheme.TextDim
    CloseNotif.Font = Enum.Font.GothamBold
    CloseNotif.TextSize = 14
    CloseNotif.Parent = Notif
    
    -- Animate in
    tween(Notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)
    
    local function closeNotification()
        tween(Notif, {Position = UDim2.new(1, 50, 0, 0)}, 0.3)
        task.wait(0.3)
        Notif:Destroy()
    end
    
    CloseNotif.MouseButton1Click:Connect(closeNotification)
    
    task.delay(duration, function()
        if Notif.Parent then
            closeNotification()
        end
    end)
end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 450)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -225)
MainFrame.BackgroundColor3 = CurrentTheme.Primary
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = CurrentTheme.Border
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

local MainShadow = Instance.new("ImageLabel")
MainShadow.Name = "Shadow"
MainShadow.Size = UDim2.new(1, 50, 1, 50)
MainShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
MainShadow.AnchorPoint = Vector2.new(0.5, 0.5)
MainShadow.BackgroundTransparency = 1
MainShadow.Image = "rbxassetid://5554236805"
MainShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
MainShadow.ImageTransparency = 0.6
MainShadow.ScaleType = Enum.ScaleType.Slice
MainShadow.SliceCenter = Rect.new(23, 23, 277, 277)
MainShadow.ZIndex = -1
MainShadow.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = CurrentTheme.Secondary
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleCover = Instance.new("Frame")
TitleCover.Size = UDim2.new(1, 0, 0.5, 0)
TitleCover.Position = UDim2.new(0, 0, 0.5, 0)
TitleCover.BackgroundColor3 = CurrentTheme.Secondary
TitleCover.BorderSizePixel = 0
TitleCover.Parent = TitleBar

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(0, 35, 0, 35)
Logo.Position = UDim2.new(0, 10, 0.5, 0)
Logo.AnchorPoint = Vector2.new(0, 0.5)
Logo.BackgroundTransparency = 1
Logo.Text = "⚡"
Logo.TextSize = 24
Logo.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 200, 1, 0)
TitleText.Position = UDim2.new(0, 45, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Private Server HUB"
TitleText.TextColor3 = CurrentTheme.Text
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 16
TitleText.Parent = TitleBar

local VersionLabel = Instance.new("TextLabel")
VersionLabel.Size = UDim2.new(0, 40, 0, 20)
VersionLabel.Position = UDim2.new(0, 195, 0.5, 0)
VersionLabel.AnchorPoint = Vector2.new(0, 0.5)
VersionLabel.BackgroundColor3 = CurrentTheme.Accent
VersionLabel.Text = "v"..Config.Version
VersionLabel.TextColor3 = CurrentTheme.Text
VersionLabel.Font = Enum.Font.GothamBold
VersionLabel.TextSize = 10
VersionLabel.Parent = TitleBar

local VersionCorner = Instance.new("UICorner")
VersionCorner.CornerRadius = UDim.new(0, 4)
VersionCorner.Parent = VersionLabel

-- Window Controls
local WindowControls = Instance.new("Frame")
WindowControls.Size = UDim2.new(0, 90, 0, 30)
WindowControls.Position = UDim2.new(1, -100, 0.5, 0)
WindowControls.AnchorPoint = Vector2.new(0, 0.5)
WindowControls.BackgroundTransparency = 1
WindowControls.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(0, 0, 0, 0)
MinimizeBtn.BackgroundColor3 = CurrentTheme.Tertiary
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = CurrentTheme.TextDim
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 14
MinimizeBtn.Parent = WindowControls

local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 6)
MinBtnCorner.Parent = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(0, 55, 0, 0)
CloseBtn.BackgroundColor3 = CurrentTheme.Error
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = WindowControls

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

-- Tab System
local TabHolder = Instance.new("Frame")
TabHolder.Size = UDim2.new(0, 120, 1, -55)
TabHolder.Position = UDim2.new(0, 0, 0, 50)
TabHolder.BackgroundColor3 = CurrentTheme.Secondary
TabHolder.BorderSizePixel = 0
TabHolder.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 5)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.Parent = TabHolder

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 10)
TabPadding.Parent = TabHolder

local ContentHolder = Instance.new("Frame")
ContentHolder.Size = UDim2.new(1, -130, 1, -55)
ContentHolder.Position = UDim2.new(0, 125, 0, 50)
ContentHolder.BackgroundTransparency = 1
ContentHolder.ClipsDescendants = true
ContentHolder.Parent = MainFrame

-- Tab Creation Function
local Tabs = {}
local CurrentTab = nil

local function createTab(name, icon, content)
    local TabButton = Instance.new("TextButton")
    TabButton.Name = name
    TabButton.Size = UDim2.new(0, 100, 0, 40)
    TabButton.BackgroundColor3 = CurrentTheme.Tertiary
    TabButton.BackgroundTransparency = 1
    TabButton.Text = ""
    TabButton.Parent = TabHolder
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 8)
    TabCorner.Parent = TabButton
    
    local TabIcon = Instance.new("TextLabel")
    TabIcon.Size = UDim2.new(0, 25, 1, 0)
    TabIcon.Position = UDim2.new(0, 8, 0, 0)
    TabIcon.BackgroundTransparency = 1
    TabIcon.Text = icon
    TabIcon.TextSize = 16
    TabIcon.Parent = TabButton
    
    local TabText = Instance.new("TextLabel")
    TabText.Size = UDim2.new(1, -40, 1, 0)
    TabText.Position = UDim2.new(0, 35, 0, 0)
    TabText.BackgroundTransparency = 1
    TabText.Text = name
    TabText.TextColor3 = CurrentTheme.TextDim
    TabText.TextXAlignment = Enum.TextXAlignment.Left
    TabText.Font = Enum.Font.GothamSemibold
    TabText.TextSize = 12
    TabText.Parent = TabButton
    
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = name.."Content"
    ContentFrame.Size = UDim2.new(1, 0, 1, 0)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ScrollBarThickness = 4
    ContentFrame.ScrollBarImageColor3 = CurrentTheme.Accent
    ContentFrame.Visible = false
    ContentFrame.Parent = ContentHolder
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 10)
    ContentLayout.Parent = ContentFrame
    
    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingTop = UDim.new(0, 5)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.Parent = ContentFrame
    
    Tabs[name] = {
        Button = TabButton,
        Content = ContentFrame,
        Text = TabText
    }
    
    TabButton.MouseButton1Click:Connect(function()
        if CurrentTab then
            Tabs[CurrentTab].Content.Visible = false
            tween(Tabs[CurrentTab].Button, {BackgroundTransparency = 1}, 0.2)
            Tabs[CurrentTab].Text.TextColor3 = CurrentTheme.TextDim
        end
        CurrentTab = name
        ContentFrame.Visible = true
        tween(TabButton, {BackgroundTransparency = 0}, 0.2)
        TabText.TextColor3 = CurrentTheme.Text
    end)
    
    -- Hover effect
    TabButton.MouseEnter:Connect(function()
        if CurrentTab ~= name then
            tween(TabButton, {BackgroundTransparency = 0.5}, 0.2)
        end
    end)
    
    TabButton.MouseLeave:Connect(function()
        if CurrentTab ~= name then
            tween(TabButton, {BackgroundTransparency = 1}, 0.2)
        end
    end)
    
    return ContentFrame
end

-- Create Tabs
local JoinTab = createTab("Join", "🚀", {})
local FavoritesTab = createTab("Favorites", "⭐", {})
local HistoryTab = createTab("History", "📜", {})
local SettingsTab = createTab("Settings", "⚙️", {})

-- Select first tab
Tabs["Join"].Button.BackgroundTransparency = 0
Tabs["Join"].Content.Visible = true
Tabs["Join"].Text.TextColor3 = CurrentTheme.Text
CurrentTab = "Join"

-- === JOIN TAB CONTENT ===
local function createInputBox(parent, placeholder, yPos)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -10, 0, 45)
    Container.BackgroundColor3 = CurrentTheme.Secondary
    Container.BorderSizePixel = 0
    Container.Parent = parent
    
    local ContainerCorner = Instance.new("UICorner")
    ContainerCorner.CornerRadius = UDim.new(0, 8)
    ContainerCorner.Parent = Container
    
    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, -20, 1, 0)
    Input.Position = UDim2.new(0, 10, 0, 0)
    Input.BackgroundTransparency = 1
    Input.PlaceholderText = placeholder
    Input.PlaceholderColor3 = CurrentTheme.TextDim
    Input.Text = ""
    Input.TextColor3 = CurrentTheme.Text
    Input.TextXAlignment = Enum.TextXAlignment.Left
    Input.Font = Enum.Font.Gotham
    Input.TextSize = 14
    Input.ClearTextOnFocus = false
    Input.Parent = Container
    
    return Input, Container
end

local function createButton(parent, text, color, size)
    local Button = Instance.new("TextButton")
    Button.Size = size or UDim2.new(1, -10, 0, 45)
    Button.BackgroundColor3 = color or CurrentTheme.Accent
    Button.Text = text
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 14
    Button.AutoButtonColor = false
    Button.Parent = parent
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Button
    
    -- Hover effect
    Button.MouseEnter:Connect(function()
        tween(Button, {BackgroundColor3 = Color3.new(
            math.clamp(color.R * 0.85, 0, 1),
            math.clamp(color.G * 0.85, 0, 1),
            math.clamp(color.B * 0.85, 0, 1)
        )}, 0.2)
    end)
    
    Button.MouseLeave:Connect(function()
        tween(Button, {BackgroundColor3 = color}, 0.2)
    end)
    
    return Button
end

-- Join Section Header
local JoinHeader = Instance.new("TextLabel")
JoinHeader.Size = UDim2.new(1, -10, 0, 30)
JoinHeader.BackgroundTransparency = 1
JoinHeader.Text = "🎮 Join Private Server"
JoinHeader.TextColor3 = CurrentTheme.Text
JoinHeader.TextXAlignment = Enum.TextXAlignment.Left
JoinHeader.Font = Enum.Font.GothamBold
JoinHeader.TextSize = 16
JoinHeader.Parent = JoinTab

local PlaceIdInput, PlaceIdContainer = createInputBox(JoinTab, "Enter PlaceId...", 0)

-- Game Info Display
local GameInfoFrame = Instance.new("Frame")
GameInfoFrame.Size = UDim2.new(1, -10, 0, 60)
GameInfoFrame.BackgroundColor3 = CurrentTheme.Secondary
GameInfoFrame.BorderSizePixel = 0
GameInfoFrame.Visible = false
GameInfoFrame.Parent = JoinTab

local GameInfoCorner = Instance.new("UICorner")
GameInfoCorner.CornerRadius = UDim.new(0, 8)
GameInfoCorner.Parent = GameInfoFrame

local GameNameLabel = Instance.new("TextLabel")
GameNameLabel.Size = UDim2.new(1, -20, 0, 25)
GameNameLabel.Position = UDim2.new(0, 10, 0, 8)
GameNameLabel.BackgroundTransparency = 1
GameNameLabel.Text = "Loading..."
GameNameLabel.TextColor3 = CurrentTheme.Text
GameNameLabel.TextXAlignment = Enum.TextXAlignment.Left
GameNameLabel.Font = Enum.Font.GothamBold
GameNameLabel.TextSize = 14
GameNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
GameNameLabel.Parent = GameInfoFrame

local GameIdLabel = Instance.new("TextLabel")
GameIdLabel.Size = UDim2.new(1, -20, 0, 20)
GameIdLabel.Position = UDim2.new(0, 10, 0, 32)
GameIdLabel.BackgroundTransparency = 1
GameIdLabel.Text = "PlaceId: ..."
GameIdLabel.TextColor3 = CurrentTheme.TextDim
GameIdLabel.TextXAlignment = Enum.TextXAlignment.Left
GameIdLabel.Font = Enum.Font.Gotham
GameIdLabel.TextSize = 12
GameIdLabel.Parent = GameInfoFrame

-- Update game info when PlaceId changes
PlaceIdInput:GetPropertyChangedSignal("Text"):Connect(function()
    local placeId = tonumber(PlaceIdInput.Text)
    if placeId and placeId > 0 then
        GameInfoFrame.Visible = true
        GameNameLabel.Text = "Loading..."
        GameIdLabel.Text = "PlaceId: "..formatNumber(placeId)
        
        task.spawn(function()
            local name = getGameName(placeId)
            if tonumber(PlaceIdInput.Text) == placeId then
                GameNameLabel.Text = name
            end
        end)
    else
        GameInfoFrame.Visible = false
    end
end)

-- Button Container
local ButtonRow = Instance.new("Frame")
ButtonRow.Size = UDim2.new(1, -10, 0, 45)
ButtonRow.BackgroundTransparency = 1
ButtonRow.Parent = JoinTab

local ButtonRowLayout = Instance.new("UIListLayout")
ButtonRowLayout.FillDirection = Enum.FillDirection.Horizontal
ButtonRowLayout.Padding = UDim.new(0, 10)
ButtonRowLayout.Parent = ButtonRow

local JoinButton = createButton(ButtonRow, "🚀 Generate & Join", CurrentTheme.Accent, UDim2.new(0.65, -5, 1, 0))
local AddFavButton = createButton(ButtonRow, "⭐ Save", CurrentTheme.Success, UDim2.new(0.35, -5, 1, 0))

-- Code Display
local CodeHeader = Instance.new("TextLabel")
CodeHeader.Size = UDim2.new(1, -10, 0, 25)
CodeHeader.BackgroundTransparency = 1
CodeHeader.Text = "📋 Generated Access Code"
CodeHeader.TextColor3 = CurrentTheme.Text
CodeHeader.TextXAlignment = Enum.TextXAlignment.Left
CodeHeader.Font = Enum.Font.GothamBold
CodeHeader.TextSize = 14
CodeHeader.Parent = JoinTab

local CodeDisplay = Instance.new("Frame")
CodeDisplay.Size = UDim2.new(1, -10, 0, 80)
CodeDisplay.BackgroundColor3 = CurrentTheme.Secondary
CodeDisplay.BorderSizePixel = 0
CodeDisplay.Parent = JoinTab

local CodeCorner = Instance.new("UICorner")
CodeCorner.CornerRadius = UDim.new(0, 8)
CodeCorner.Parent = CodeDisplay

local CodeText = Instance.new("TextLabel")
CodeText.Size = UDim2.new(1, -60, 1, -10)
CodeText.Position = UDim2.new(0, 10, 0, 5)
CodeText.BackgroundTransparency = 1
CodeText.Text = "Code will appear here..."
CodeText.TextColor3 = CurrentTheme.TextDim
CodeText.TextXAlignment = Enum.TextXAlignment.Left
CodeText.TextYAlignment = Enum.TextYAlignment.Top
CodeText.Font = Enum.Font.Code
CodeText.TextSize = 11
CodeText.TextWrapped = true
CodeText.Parent = CodeDisplay

local CopyCodeBtn = Instance.new("TextButton")
CopyCodeBtn.Size = UDim2.new(0, 40, 0, 40)
CopyCodeBtn.Position = UDim2.new(1, -50, 0.5, 0)
CopyCodeBtn.AnchorPoint = Vector2.new(0, 0.5)
CopyCodeBtn.BackgroundColor3 = CurrentTheme.Tertiary
CopyCodeBtn.Text = "📋"
CopyCodeBtn.TextSize = 18
CopyCodeBtn.Parent = CodeDisplay

local CopyCodeCorner = Instance.new("UICorner")
CopyCodeCorner.CornerRadius = UDim.new(0, 8)
CopyCodeCorner.Parent = CopyCodeBtn

local LastGeneratedCode = ""

-- Join Button Logic
JoinButton.MouseButton1Click:Connect(function()
    local placeId = tonumber(PlaceIdInput.Text)
    if placeId and placeId > 0 then
        JoinButton.Text = "⏳ Generating..."
        
        local code = generateCode(placeId)
        LastGeneratedCode = code
        CodeText.Text = code
        CodeText.TextColor3 = CurrentTheme.Text
        
        if setclipboard then
            setclipboard(code.."\n"..tostring(placeId))
        end
        
        local gameName = getGameName(placeId)
        addToHistory(placeId, gameName)
        
        JoinButton.Text = "🔄 Teleporting..."
        notify("Teleporting", "Joining private server for "..gameName, "Info")
        
        local success = pcall(function()
            RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(placeId, "", code)
        end)
        
        task.wait(2)
        JoinButton.Text = "🚀 Generate & Join"
    else
        notify("Error", "Please enter a valid PlaceId", "Error")
        JoinButton.Text = "❌ Invalid PlaceId"
        task.wait(1.5)
        JoinButton.Text = "🚀 Generate & Join"
    end
end)

-- Add to Favorites
AddFavButton.MouseButton1Click:Connect(function()
    local placeId = tonumber(PlaceIdInput.Text)
    if placeId and placeId > 0 then
        local gameName = getGameName(placeId)
        Data.Favorites[tostring(placeId)] = {
            Name = gameName,
            PlaceId = placeId,
            Category = "Default",
            Added = os.time()
        }
        saveData()
        notify("Saved", gameName.." added to favorites!", "Success")
    else
        notify("Error", "Please enter a valid PlaceId first", "Error")
    end
end)

-- Copy Code Button
CopyCodeBtn.MouseButton1Click:Connect(function()
    if LastGeneratedCode ~= "" then
        if setclipboard then
            setclipboard(LastGeneratedCode)
        end
        notify("Copied", "Access code copied to clipboard!", "Success")
    end
end)

-- === FAVORITES TAB ===
local FavHeader = Instance.new("TextLabel")
FavHeader.Size = UDim2.new(1, -10, 0, 30)
FavHeader.BackgroundTransparency = 1
FavHeader.Text = "⭐ Saved Servers"
FavHeader.TextColor3 = CurrentTheme.Text
FavHeader.TextXAlignment = Enum.TextXAlignment.Left
FavHeader.Font = Enum.Font.GothamBold
FavHeader.TextSize = 16
FavHeader.Parent = FavoritesTab

local FavSearchInput, FavSearchContainer = createInputBox(FavoritesTab, "🔍 Search favorites...", 0)

local FavListContainer = Instance.new("Frame")
FavListContainer.Size = UDim2.new(1, -10, 0, 250)
FavListContainer.BackgroundTransparency = 1
FavListContainer.ClipsDescendants = true
FavListContainer.Parent = FavoritesTab

local FavListLayout = Instance.new("UIListLayout")
FavListLayout.Padding = UDim.new(0, 8)
FavListLayout.Parent = FavListContainer

local function createFavEntry(name, data)
    local Entry = Instance.new("Frame")
    Entry.Size = UDim2.new(1, 0, 0, 55)
    Entry.BackgroundColor3 = CurrentTheme.Secondary
    Entry.BorderSizePixel = 0
    Entry.Parent = FavListContainer
    
    local EntryCorner = Instance.new("UICorner")
    EntryCorner.CornerRadius = UDim.new(0, 8)
    EntryCorner.Parent = Entry
    
    local GameName = Instance.new("TextLabel")
    GameName.Size = UDim2.new(1, -120, 0, 22)
    GameName.Position = UDim2.new(0, 12, 0, 8)
    GameName.BackgroundTransparency = 1
    GameName.Text = data.Name or "Unknown"
    GameName.TextColor3 = CurrentTheme.Text
    GameName.TextXAlignment = Enum.TextXAlignment.Left
    GameName.Font = Enum.Font.GothamBold
    GameName.TextSize = 13
    GameName.TextTruncate = Enum.TextTruncate.AtEnd
    GameName.Parent = Entry
    
    local PlaceIdLabel = Instance.new("TextLabel")
    PlaceIdLabel.Size = UDim2.new(1, -120, 0, 18)
    PlaceIdLabel.Position = UDim2.new(0, 12, 0, 30)
    PlaceIdLabel.BackgroundTransparency = 1
    PlaceIdLabel.Text = "PlaceId: "..formatNumber(data.PlaceId)
    PlaceIdLabel.TextColor3 = CurrentTheme.TextDim
    PlaceIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    PlaceIdLabel.Font = Enum.Font.Gotham
    PlaceIdLabel.TextSize = 11
    PlaceIdLabel.Parent = Entry
    
    local JoinFavBtn = Instance.new("TextButton")
    JoinFavBtn.Size = UDim2.new(0, 45, 0, 35)
    JoinFavBtn.Position = UDim2.new(1, -110, 0.5, 0)
    JoinFavBtn.AnchorPoint = Vector2.new(0, 0.5)
    JoinFavBtn.BackgroundColor3 = CurrentTheme.Accent
    JoinFavBtn.Text = "🚀"
    JoinFavBtn.TextSize = 16
    JoinFavBtn.Parent = Entry
    
    local JoinFavCorner = Instance.new("UICorner")
    JoinFavCorner.CornerRadius = UDim.new(0, 6)
    JoinFavCorner.Parent = JoinFavBtn
    
    local DeleteFavBtn = Instance.new("TextButton")
    DeleteFavBtn.Size = UDim2.new(0, 45, 0, 35)
    DeleteFavBtn.Position = UDim2.new(1, -55, 0.5, 0)
    DeleteFavBtn.AnchorPoint = Vector2.new(0, 0.5)
    DeleteFavBtn.BackgroundColor3 = CurrentTheme.Error
    DeleteFavBtn.Text = "🗑️"
    DeleteFavBtn.TextSize = 16
    DeleteFavBtn.Parent = Entry
    
    local DeleteFavCorner = Instance.new("UICorner")
    DeleteFavCorner.CornerRadius = UDim.new(0, 6)
    DeleteFavCorner.Parent = DeleteFavBtn
    
    JoinFavBtn.MouseButton1Click:Connect(function()
        local code = generateCode(data.PlaceId)
        if setclipboard then
            setclipboard(code.."\n"..tostring(data.PlaceId))
        end
        notify("Teleporting", "Joining "..data.Name, "Info")
        pcall(function()
            RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(data.PlaceId, "", code)
        end)
    end)
    
    DeleteFavBtn.MouseButton1Click:Connect(function()
        Data.Favorites[name] = nil
        saveData()
        Entry:Destroy()
        notify("Deleted", data.Name.." removed from favorites", "Warning")
    end)
    
    return Entry
end

local function refreshFavorites(filter)
    for _, child in ipairs(FavListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    filter = filter and filter:lower() or ""
    
    for id, data in pairs(Data.Favorites) do
        if filter == "" or data.Name:lower():find(filter) or tostring(data.PlaceId):find(filter) then
            createFavEntry(id, data)
        end
    end
    
    FavoritesTab.CanvasSize = UDim2.new(0, 0, 0, FavoritesTab.UIListLayout.AbsoluteContentSize.Y + 20)
end

FavSearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    refreshFavorites(FavSearchInput.Text)
end)

-- Initial load
task.spawn(refreshFavorites)

-- === HISTORY TAB ===
local HistHeader = Instance.new("TextLabel")
HistHeader.Size = UDim2.new(1, -10, 0, 30)
HistHeader.BackgroundTransparency = 1
HistHeader.Text = "📜 Recent Servers"
HistHeader.TextColor3 = CurrentTheme.Text
HistHeader.TextXAlignment = Enum.TextXAlignment.Left
HistHeader.Font = Enum.Font.GothamBold
HistHeader.TextSize = 16
HistHeader.Parent = HistoryTab

local ClearHistBtn = createButton(HistoryTab, "🗑️ Clear History", CurrentTheme.Error, UDim2.new(1, -10, 0, 35))

local HistListContainer = Instance.new("Frame")
HistListContainer.Size = UDim2.new(1, -10, 0, 250)
HistListContainer.BackgroundTransparency = 1
HistListContainer.ClipsDescendants = true
HistListContainer.Parent = HistoryTab

local HistListLayout = Instance.new("UIListLayout")
HistListLayout.Padding = UDim.new(0, 8)
HistListLayout.Parent = HistListContainer

local function formatTime(timestamp)
    local diff = os.time() - timestamp
    if diff < 60 then return "Just now"
    elseif diff < 3600 then return math.floor(diff/60).." min ago"
    elseif diff < 86400 then return math.floor(diff/3600).." hours ago"
    else return math.floor(diff/86400).." days ago" end
end

local function refreshHistory()
    for _, child in ipairs(HistListContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for i, entry in ipairs(Data.History) do
        local HistEntry = Instance.new("Frame")
        HistEntry.Size = UDim2.new(1, 0, 0, 50)
        HistEntry.BackgroundColor3 = CurrentTheme.Secondary
        HistEntry.BorderSizePixel = 0
        HistEntry.Parent = HistListContainer
        
        local HistCorner = Instance.new("UICorner")
        HistCorner.CornerRadius = UDim.new(0, 8)
        HistCorner.Parent = HistEntry
        
        local HistName = Instance.new("TextLabel")
        HistName.Size = UDim2.new(1, -70, 0, 22)
        HistName.Position = UDim2.new(0, 12, 0, 6)
        HistName.BackgroundTransparency = 1
        HistName.Text = entry.Name
        HistName.TextColor3 = CurrentTheme.Text
        HistName.TextXAlignment = Enum.TextXAlignment.Left
        HistName.Font = Enum.Font.GothamSemibold
        HistName.TextSize = 12
        HistName.TextTruncate = Enum.TextTruncate.AtEnd
        HistName.Parent = HistEntry
        
        local HistTime = Instance.new("TextLabel")
        HistTime.Size = UDim2.new(1, -70, 0, 16)
        HistTime.Position = UDim2.new(0, 12, 0, 28)
        HistTime.BackgroundTransparency = 1
        HistTime.Text = formatTime(entry.Time).." • "..formatNumber(entry.PlaceId)
        HistTime.TextColor3 = CurrentTheme.TextDim
        HistTime.TextXAlignment = Enum.TextXAlignment.Left
        HistTime.Font = Enum.Font.Gotham
        HistTime.TextSize = 10
        HistTime.Parent = HistEntry
        
        local RejoinBtn = Instance.new("TextButton")
        RejoinBtn.Size = UDim2.new(0, 40, 0, 32)
        RejoinBtn.Position = UDim2.new(1, -52, 0.5, 0)
        RejoinBtn.AnchorPoint = Vector2.new(0, 0.5)
        RejoinBtn.BackgroundColor3 = CurrentTheme.Accent
        RejoinBtn.Text = "🚀"
        RejoinBtn.TextSize = 14
        RejoinBtn.Parent = HistEntry
        
        local RejoinCorner = Instance.new("UICorner")
        RejoinCorner.CornerRadius = UDim.new(0, 6)
        RejoinCorner.Parent = RejoinBtn
        
        RejoinBtn.MouseButton1Click:Connect(function()
            local code = generateCode(entry.PlaceId)
            notify("Teleporting", "Rejoining "..entry.Name, "Info")
            pcall(function()
                RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(entry.PlaceId, "", code)
            end)
        end)
    end
    
    HistoryTab.CanvasSize = UDim2.new(0, 0, 0, HistoryTab.UIListLayout.AbsoluteContentSize.Y + 20)
end

ClearHistBtn.MouseButton1Click:Connect(function()
    Data.History = {}
    saveData()
    refreshHistory()
    notify("Cleared", "History has been cleared", "Success")
end)

task.spawn(refreshHistory)

-- === SETTINGS TAB ===
local SettHeader = Instance.new("TextLabel")
SettHeader.Size = UDim2.new(1, -10, 0, 30)
SettHeader.BackgroundTransparency = 1
SettHeader.Text = "⚙️ Settings"
SettHeader.TextColor3 = CurrentTheme.Text
SettHeader.TextXAlignment = Enum.TextXAlignment.Left
SettHeader.Font = Enum.Font.GothamBold
SettHeader.TextSize = 16
SettHeader.Parent = SettingsTab

local function createToggle(parent, text, default, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -10, 0, 45)
    ToggleFrame.BackgroundColor3 = CurrentTheme.Secondary
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = parent
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleFrame
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(1, -70, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = text
    ToggleLabel.TextColor3 = CurrentTheme.Text
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Font = Enum.Font.GothamSemibold
    ToggleLabel.TextSize = 13
    ToggleLabel.Parent = ToggleFrame
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 50, 0, 26)
    ToggleBtn.Position = UDim2.new(1, -60, 0.5, 0)
    ToggleBtn.AnchorPoint = Vector2.new(0, 0.5)
    ToggleBtn.BackgroundColor3 = default and CurrentTheme.Success or CurrentTheme.Tertiary
    ToggleBtn.Text = ""
    ToggleBtn.Parent = ToggleFrame
    
    local ToggleBtnCorner = Instance.new("UICorner")
    ToggleBtnCorner.CornerRadius = UDim.new(1, 0)
    ToggleBtnCorner.Parent = ToggleBtn
    
    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Size = UDim2.new(0, 20, 0, 20)
    ToggleCircle.Position = default and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    ToggleCircle.AnchorPoint = Vector2.new(0, 0.5)
    ToggleCircle.BackgroundColor3 = Color3.new(1, 1, 1)
    ToggleCircle.Parent = ToggleBtn
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = ToggleCircle
    
    local state = default
    
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            tween(ToggleBtn, {BackgroundColor3 = CurrentTheme.Success}, 0.2)
            tween(ToggleCircle, {Position = UDim2.new(1, -23, 0.5, 0)}, 0.2)
        else
            tween(ToggleBtn, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
            tween(ToggleCircle, {Position = UDim2.new(0, 3, 0.5, 0)}, 0.2)
        end
        callback(state)
    end)
    
    return ToggleFrame
end

createToggle(SettingsTab, "🔄 Auto Rejoin on Disconnect", Data.Settings.AutoRejoin, function(state)
    Data.Settings.AutoRejoin = state
    Config.AutoRejoin = state
    saveData()
end)

createToggle(SettingsTab, "⏸️ Anti-AFK", Data.Settings.AntiAFK, function(state)
    Data.Settings.AntiAFK = state
    Config.AntiAFK = state
    saveData()
end)

createToggle(SettingsTab, "🔔 Notifications", Data.Settings.Notifications, function(state)
    Data.Settings.Notifications = state
    saveData()
end)

-- Theme Selector
local ThemeHeader = Instance.new("TextLabel")
ThemeHeader.Size = UDim2.new(1, -10, 0, 25)
ThemeHeader.BackgroundTransparency = 1
ThemeHeader.Text = "🎨 Theme"
ThemeHeader.TextColor3 = CurrentTheme.Text
ThemeHeader.TextXAlignment = Enum.TextXAlignment.Left
ThemeHeader.Font = Enum.Font.GothamSemibold
ThemeHeader.TextSize = 13
ThemeHeader.Parent = SettingsTab

local ThemeContainer = Instance.new("Frame")
ThemeContainer.Size = UDim2.new(1, -10, 0, 40)
ThemeContainer.BackgroundTransparency = 1
ThemeContainer.Parent = SettingsTab

local ThemeLayout = Instance.new("UIListLayout")
ThemeLayout.FillDirection = Enum.FillDirection.Horizontal
ThemeLayout.Padding = UDim.new(0, 8)
ThemeLayout.Parent = ThemeContainer

for themeName, _ in pairs(Themes) do
    local ThemeBtn = Instance.new("TextButton")
    ThemeBtn.Size = UDim2.new(0, 75, 0, 35)
    ThemeBtn.BackgroundColor3 = Themes[themeName].Accent
    ThemeBtn.Text = themeName
    ThemeBtn.TextColor3 = Color3.new(1, 1, 1)
    ThemeBtn.Font = Enum.Font.GothamSemibold
    ThemeBtn.TextSize = 11
    ThemeBtn.Parent = ThemeContainer
    
    local ThemeBtnCorner = Instance.new("UICorner")
    ThemeBtnCorner.CornerRadius = UDim.new(0, 6)
    ThemeBtnCorner.Parent = ThemeBtn
    
    ThemeBtn.MouseButton1Click:Connect(function()
        Data.Settings.Theme = themeName
        saveData()
        notify("Theme Changed", "Restart script to apply "..themeName.." theme", "Info")
    end)
end

-- Export/Import
local ExportBtn = createButton(SettingsTab, "📤 Export Favorites", CurrentTheme.Accent, UDim2.new(1, -10, 0, 40))
local ImportBtn = createButton(SettingsTab, "📥 Import Favorites", CurrentTheme.Tertiary, UDim2.new(1, -10, 0, 40))

ExportBtn.MouseButton1Click:Connect(function()
    local exportData = HttpService:JSONEncode(Data.Favorites)
    if setclipboard then
        setclipboard(exportData)
        notify("Exported", "Favorites copied to clipboard!", "Success")
    end
end)

ImportBtn.MouseButton1Click:Connect(function()
    notify("Import", "Paste JSON data in PlaceId field, then click Import again", "Info")
end)

-- Credits
local CreditsLabel = Instance.new("TextLabel")
CreditsLabel.Size = UDim2.new(1, -10, 0, 40)
CreditsLabel.BackgroundTransparency = 1
CreditsLabel.Text = "Made with ❤️ by ADMC\nPress F9 to toggle UI"
CreditsLabel.TextColor3 = CurrentTheme.TextDim
CreditsLabel.Font = Enum.Font.Gotham
CreditsLabel.TextSize = 11
CreditsLabel.Parent = SettingsTab

-- === Dragging ===
local dragging, dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- === Window Controls ===
local minimized = false
local originalSize = MainFrame.Size

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tween(MainFrame, {Size = UDim2.new(0, 500, 0, 45)}, 0.3)
        MinimizeBtn.Text = "+"
    else
        tween(MainFrame, {Size = originalSize}, 0.3)
        MinimizeBtn.Text = "─"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3)
    task.wait(0.3)
    ScreenGui:Destroy()
end)

-- === Keybind Toggle ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Config.ToggleKey then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- === Anti-AFK ===
Players.LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

-- === Auto-Rejoin ===
local promptGui = CoreGui:WaitForChild("RobloxPromptGui", 5)
if promptGui then
    local overlay = promptGui:WaitForChild("promptOverlay", 5)
    if overlay then
        overlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" and Config.AutoRejoin then
                task.wait(2)
                TeleportService:Teleport(game.PlaceId)
            end
        end)
    end
end

-- === Opening Animation ===
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
task.wait(0.1)
tween(MainFrame, {Size = UDim2.new(0, 500, 0, 450), Position = UDim2.new(0.5, -250, 0.5, -225)}, 0.4, Enum.EasingStyle.Back)

-- Welcome notification
task.wait(0.5)
notify("Welcome!", "Private Server HUB v"..Config.Version.." loaded successfully!", "Success", 4)

print("⚡ Private Server HUB v2.0 loaded successfully!")
print("🎮 Press F9 to toggle the UI")