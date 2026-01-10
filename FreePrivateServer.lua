-- ⚡ Private Server HUB v3.0 by ADMC
-- 🚀 Features: Dashboard, Glassmorphism UI, Categories, Batch Queue, Stats, 
--    Server Preview, Custom Themes, Quick Actions, Keyboard Shortcuts, and more!

-- === Configuration ===
local Config = {
    Version = "3.0",
    ToggleKey = Enum.KeyCode.F9,
    QuickJoinKey = Enum.KeyCode.F10,
    Theme = "Neon",
    AutoRejoin = true,
    AntiAFK = true,
    Notifications = true,
    CompactMode = false,
    SoundEffects = true,
    AnimationSpeed = 1,
    SavePath = "PrivateServerHUB_v3/",
    MaxHistory = 50,
    MaxQueue = 10,
    AutoBackup = true
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
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

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

-- === Extended Theme System ===
local Themes = {
    Neon = {
        Primary = Color3.fromRGB(13, 13, 20),
        Secondary = Color3.fromRGB(20, 20, 32),
        Tertiary = Color3.fromRGB(28, 28, 45),
        Accent = Color3.fromRGB(0, 212, 255),
        AccentSecondary = Color3.fromRGB(138, 43, 226),
        AccentGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 212, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(138, 43, 226))
        }),
        Success = Color3.fromRGB(0, 255, 136),
        Warning = Color3.fromRGB(255, 196, 0),
        Error = Color3.fromRGB(255, 71, 87),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(140, 140, 160),
        TextMuted = Color3.fromRGB(80, 80, 100),
        Border = Color3.fromRGB(45, 45, 70),
        Glow = Color3.fromRGB(0, 212, 255),
        Glass = 0.85
    },
    Dark = {
        Primary = Color3.fromRGB(18, 18, 24),
        Secondary = Color3.fromRGB(26, 26, 36),
        Tertiary = Color3.fromRGB(36, 36, 50),
        Accent = Color3.fromRGB(88, 101, 242),
        AccentSecondary = Color3.fromRGB(114, 137, 218),
        AccentGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(114, 137, 218))
        }),
        Success = Color3.fromRGB(87, 242, 135),
        Warning = Color3.fromRGB(254, 231, 92),
        Error = Color3.fromRGB(237, 66, 69),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(185, 185, 195),
        TextMuted = Color3.fromRGB(100, 100, 120),
        Border = Color3.fromRGB(50, 50, 70),
        Glow = Color3.fromRGB(88, 101, 242),
        Glass = 0.9
    },
    Light = {
        Primary = Color3.fromRGB(250, 250, 255),
        Secondary = Color3.fromRGB(240, 240, 248),
        Tertiary = Color3.fromRGB(230, 230, 240),
        Accent = Color3.fromRGB(79, 70, 229),
        AccentSecondary = Color3.fromRGB(99, 102, 241),
        AccentGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(79, 70, 229)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 102, 241))
        }),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(245, 158, 11),
        Error = Color3.fromRGB(239, 68, 68),
        Text = Color3.fromRGB(17, 24, 39),
        TextDim = Color3.fromRGB(75, 85, 99),
        TextMuted = Color3.fromRGB(156, 163, 175),
        Border = Color3.fromRGB(209, 213, 219),
        Glow = Color3.fromRGB(79, 70, 229),
        Glass = 0.7
    },
    Midnight = {
        Primary = Color3.fromRGB(10, 10, 18),
        Secondary = Color3.fromRGB(16, 16, 28),
        Tertiary = Color3.fromRGB(24, 24, 40),
        Accent = Color3.fromRGB(167, 139, 250),
        AccentSecondary = Color3.fromRGB(192, 132, 252),
        AccentGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(167, 139, 250)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(192, 132, 252))
        }),
        Success = Color3.fromRGB(52, 211, 153),
        Warning = Color3.fromRGB(251, 191, 36),
        Error = Color3.fromRGB(248, 113, 113),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(167, 167, 190),
        TextMuted = Color3.fromRGB(100, 100, 130),
        Border = Color3.fromRGB(45, 45, 75),
        Glow = Color3.fromRGB(167, 139, 250),
        Glass = 0.88
    },
    Ocean = {
        Primary = Color3.fromRGB(8, 27, 41),
        Secondary = Color3.fromRGB(13, 40, 60),
        Tertiary = Color3.fromRGB(18, 55, 82),
        Accent = Color3.fromRGB(56, 189, 248),
        AccentSecondary = Color3.fromRGB(14, 165, 233),
        AccentGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(56, 189, 248)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 165, 233))
        }),
        Success = Color3.fromRGB(74, 222, 128),
        Warning = Color3.fromRGB(250, 204, 21),
        Error = Color3.fromRGB(251, 113, 133),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(148, 185, 213),
        TextMuted = Color3.fromRGB(94, 130, 158),
        Border = Color3.fromRGB(30, 70, 100),
        Glow = Color3.fromRGB(56, 189, 248),
        Glass = 0.85
    },
    Rose = {
        Primary = Color3.fromRGB(25, 15, 20),
        Secondary = Color3.fromRGB(35, 22, 30),
        Tertiary = Color3.fromRGB(50, 30, 42),
        Accent = Color3.fromRGB(244, 114, 182),
        AccentSecondary = Color3.fromRGB(236, 72, 153),
        AccentGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 114, 182)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(236, 72, 153))
        }),
        Success = Color3.fromRGB(134, 239, 172),
        Warning = Color3.fromRGB(253, 224, 71),
        Error = Color3.fromRGB(248, 113, 113),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(200, 160, 180),
        TextMuted = Color3.fromRGB(140, 100, 120),
        Border = Color3.fromRGB(80, 50, 65),
        Glow = Color3.fromRGB(244, 114, 182),
        Glass = 0.85
    },
    Forest = {
        Primary = Color3.fromRGB(12, 20, 15),
        Secondary = Color3.fromRGB(18, 32, 22),
        Tertiary = Color3.fromRGB(26, 46, 32),
        Accent = Color3.fromRGB(74, 222, 128),
        AccentSecondary = Color3.fromRGB(34, 197, 94),
        AccentGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(74, 222, 128)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 197, 94))
        }),
        Success = Color3.fromRGB(134, 239, 172),
        Warning = Color3.fromRGB(250, 204, 21),
        Error = Color3.fromRGB(248, 113, 113),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(160, 200, 170),
        TextMuted = Color3.fromRGB(100, 140, 110),
        Border = Color3.fromRGB(40, 70, 50),
        Glow = Color3.fromRGB(74, 222, 128),
        Glass = 0.85
    },
    Sunset = {
        Primary = Color3.fromRGB(28, 16, 20),
        Secondary = Color3.fromRGB(42, 24, 30),
        Tertiary = Color3.fromRGB(58, 32, 42),
        Accent = Color3.fromRGB(251, 146, 60),
        AccentSecondary = Color3.fromRGB(249, 115, 22),
        AccentGradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(251, 146, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(249, 115, 22))
        }),
        Success = Color3.fromRGB(134, 239, 172),
        Warning = Color3.fromRGB(253, 224, 71),
        Error = Color3.fromRGB(248, 113, 113),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(200, 170, 160),
        TextMuted = Color3.fromRGB(140, 110, 100),
        Border = Color3.fromRGB(90, 55, 50),
        Glow = Color3.fromRGB(251, 146, 60),
        Glass = 0.85
    }
}

local CurrentTheme = Themes[Config.Theme] or Themes.Neon

-- === Data Management ===
local Data = {
    Favorites = {},
    History = {},
    Queue = {},
    Categories = {
        {Name = "All", Icon = "📁", Color = Color3.fromRGB(100, 100, 120)},
        {Name = "Simulators", Icon = "🎮", Color = Color3.fromRGB(88, 101, 242)},
        {Name = "FPS", Icon = "🎯", Color = Color3.fromRGB(237, 66, 69)},
        {Name = "RPG", Icon = "⚔️", Color = Color3.fromRGB(167, 139, 250)},
        {Name = "Tycoon", Icon = "🏭", Color = Color3.fromRGB(74, 222, 128)},
        {Name = "Obby", Icon = "🏃", Color = Color3.fromRGB(251, 146, 60)},
        {Name = "Horror", Icon = "👻", Color = Color3.fromRGB(120, 80, 120)},
        {Name = "Other", Icon = "📦", Color = Color3.fromRGB(140, 140, 160)}
    },
    Stats = {
        TotalJoins = 0,
        TotalFavorites = 0,
        MostVisited = {},
        LastSession = 0,
        TotalPlayTime = 0
    },
    Settings = {
        Theme = "Neon",
        AutoRejoin = true,
        AntiAFK = true,
        Notifications = true,
        CompactMode = false,
        SoundEffects = true,
        AnimationSpeed = 1,
        MaxHistory = 50,
        ShowThumbnails = true,
        ConfirmDelete = true,
        QuickJoinKey = "F10"
    },
    Pinned = {},
    RecentSearches = {},
    CustomCategories = {}
}

-- === File System Functions ===
local function ensureFolder()
    if isfolder and not isfolder(Config.SavePath) then
        makefolder(Config.SavePath)
    end
    if isfolder and not isfolder(Config.SavePath.."backups/") then
        makefolder(Config.SavePath.."backups/")
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
            Data.Queue = decoded.Queue or {}
            Data.Stats = decoded.Stats or Data.Stats
            Data.Settings = decoded.Settings or Data.Settings
            Data.Pinned = decoded.Pinned or {}
            Data.RecentSearches = decoded.RecentSearches or {}
            Data.CustomCategories = decoded.CustomCategories or {}
            Config.Theme = Data.Settings.Theme
            CurrentTheme = Themes[Config.Theme] or Themes.Neon
        end
    end
end

local function saveData()
    ensureFolder()
    if writefile then
        local success = pcall(function()
            writefile(Config.SavePath.."data.json", HttpService:JSONEncode(Data))
        end)
        return success
    end
    return false
end

local function createBackup()
    if Config.AutoBackup and writefile and isfile then
        local timestamp = os.date("%Y%m%d_%H%M%S")
        pcall(function()
            writefile(Config.SavePath.."backups/backup_"..timestamp..".json", HttpService:JSONEncode(Data))
        end)
    end
end

loadData()

-- === Utility Functions ===
local function lerp(a, b, t)
    return a + (b - a) * t
end

local function tween(obj, props, duration, style, direction)
    duration = duration * (1 / Data.Settings.AnimationSpeed)
    local tweenInfo = TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, tweenInfo, props)
    tw:Play()
    return tw
end

local function springTween(obj, props, duration)
    duration = duration * (1 / Data.Settings.AnimationSpeed)
    local tweenInfo = TweenInfo.new(duration or 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
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

local function getGameThumbnail(placeId)
    local success, result = pcall(function()
        return "rbxthumb://type=GameIcon&id="..placeId.."&w=150&h=150"
    end)
    return success and result or ""
end

local function formatNumber(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    end
    return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function formatTime(timestamp)
    local diff = os.time() - timestamp
    if diff < 60 then return "Just now"
    elseif diff < 3600 then return math.floor(diff/60).."m ago"
    elseif diff < 86400 then return math.floor(diff/3600).."h ago"
    elseif diff < 604800 then return math.floor(diff/86400).."d ago"
    else return os.date("%m/%d", timestamp) end
end

local function parseGameUrl(url)
    local patterns = {
        "roblox%.com/games/(%d+)",
        "roblox%.com/experiences/(%d+)",
        "ro%.blox%.com/(%d+)",
        "^(%d+)$"
    }
    for _, pattern in ipairs(patterns) do
        local match = url:match(pattern)
        if match then return tonumber(match) end
    end
    return nil
end

local function addToHistory(placeId, name)
    -- Remove duplicate if exists
    for i, entry in ipairs(Data.History) do
        if entry.PlaceId == placeId then
            table.remove(Data.History, i)
            break
        end
    end
    
    table.insert(Data.History, 1, {
        PlaceId = placeId,
        Name = name,
        Time = os.time()
    })
    
    if #Data.History > Data.Settings.MaxHistory then
        table.remove(Data.History)
    end
    
    -- Update stats
    Data.Stats.TotalJoins = Data.Stats.TotalJoins + 1
    Data.Stats.MostVisited[tostring(placeId)] = (Data.Stats.MostVisited[tostring(placeId)] or 0) + 1
    
    saveData()
end

local function playSound(soundType)
    if not Data.Settings.SoundEffects then return end
    -- Sound effects would be implemented here
end

-- === GUI Creation ===
if CoreGui:FindFirstChild("PrivateServerHUB_v3") then
    CoreGui:FindFirstChild("PrivateServerHUB_v3"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PrivateServerHUB_v3"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

-- === Notification System ===
local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "Notifications"
NotificationHolder.Size = UDim2.new(0, 340, 1, -40)
NotificationHolder.Position = UDim2.new(1, -360, 0, 40)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = ScreenGui

local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.Padding = UDim.new(0, 12)
NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotificationLayout.Parent = NotificationHolder

local NotificationPadding = Instance.new("UIPadding")
NotificationPadding.PaddingBottom = UDim.new(0, 20)
NotificationPadding.Parent = NotificationHolder

local function notify(title, message, notifType, duration)
    if not Data.Settings.Notifications then return end
    
    notifType = notifType or "Info"
    duration = duration or 4
    
    local colors = {
        Info = CurrentTheme.Accent,
        Success = CurrentTheme.Success,
        Warning = CurrentTheme.Warning,
        Error = CurrentTheme.Error
    }
    
    local icons = {
        Info = "💡",
        Success = "✅",
        Warning = "⚠️",
        Error = "❌"
    }
    
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(1, 0, 0, 80)
    Notif.Position = UDim2.new(1, 60, 0, 0)
    Notif.BackgroundColor3 = CurrentTheme.Secondary
    Notif.BackgroundTransparency = 0.05
    Notif.BorderSizePixel = 0
    Notif.ClipsDescendants = true
    Notif.Parent = NotificationHolder
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 12)
    NotifCorner.Parent = Notif
    
    local NotifStroke = Instance.new("UIStroke")
    NotifStroke.Color = CurrentTheme.Border
    NotifStroke.Thickness = 1
    NotifStroke.Transparency = 0.5
    NotifStroke.Parent = Notif
    
    -- Gradient accent bar
    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 4, 1, 0)
    AccentBar.BackgroundColor3 = colors[notifType]
    AccentBar.BorderSizePixel = 0
    AccentBar.Parent = Notif
    
    local AccentCorner = Instance.new("UICorner")
    AccentCorner.CornerRadius = UDim.new(0, 12)
    AccentCorner.Parent = AccentBar
    
    -- Progress bar
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(1, 0, 0, 3)
    ProgressBar.Position = UDim2.new(0, 0, 1, -3)
    ProgressBar.BackgroundColor3 = colors[notifType]
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = Notif
    
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Size = UDim2.new(0, 40, 0, 40)
    IconLabel.Position = UDim2.new(0, 15, 0, 12)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = icons[notifType]
    IconLabel.TextSize = 26
    IconLabel.Parent = Notif
    
    local NotifTitle = Instance.new("TextLabel")
    NotifTitle.Size = UDim2.new(1, -100, 0, 22)
    NotifTitle.Position = UDim2.new(0, 55, 0, 12)
    NotifTitle.BackgroundTransparency = 1
    NotifTitle.Text = title
    NotifTitle.TextColor3 = CurrentTheme.Text
    NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
    NotifTitle.Font = Enum.Font.GothamBold
    NotifTitle.TextSize = 14
    NotifTitle.Parent = Notif
    
    local NotifMessage = Instance.new("TextLabel")
    NotifMessage.Size = UDim2.new(1, -70, 0, 36)
    NotifMessage.Position = UDim2.new(0, 55, 0, 34)
    NotifMessage.BackgroundTransparency = 1
    NotifMessage.Text = message
    NotifMessage.TextColor3 = CurrentTheme.TextDim
    NotifMessage.TextXAlignment = Enum.TextXAlignment.Left
    NotifMessage.TextYAlignment = Enum.TextYAlignment.Top
    NotifMessage.Font = Enum.Font.Gotham
    NotifMessage.TextSize = 12
    NotifMessage.TextWrapped = true
    NotifMessage.Parent = Notif
    
    local CloseNotif = Instance.new("TextButton")
    CloseNotif.Size = UDim2.new(0, 28, 0, 28)
    CloseNotif.Position = UDim2.new(1, -38, 0, 8)
    CloseNotif.BackgroundColor3 = CurrentTheme.Tertiary
    CloseNotif.BackgroundTransparency = 0.5
    CloseNotif.Text = "✕"
    CloseNotif.TextColor3 = CurrentTheme.TextDim
    CloseNotif.Font = Enum.Font.GothamBold
    CloseNotif.TextSize = 12
    CloseNotif.Parent = Notif
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseNotif
    
    -- Animate in
    springTween(Notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.4)
    
    -- Progress animation
    tween(ProgressBar, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear)
    
    local function closeNotification()
        tween(Notif, {Position = UDim2.new(1, 60, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        Notif:Destroy()
    end
    
    CloseNotif.MouseButton1Click:Connect(closeNotification)
    CloseNotif.MouseEnter:Connect(function()
        tween(CloseNotif, {BackgroundTransparency = 0}, 0.2)
    end)
    CloseNotif.MouseLeave:Connect(function()
        tween(CloseNotif, {BackgroundTransparency = 0.5}, 0.2)
    end)
    
    task.delay(duration, function()
        if Notif.Parent then
            closeNotification()
        end
    end)
    
    playSound("notification")
end

-- === Main Window ===
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 620, 0, 500)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -250)
MainFrame.BackgroundColor3 = CurrentTheme.Primary
MainFrame.BackgroundTransparency = 0.02
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = CurrentTheme.Border
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3
MainStroke.Parent = MainFrame

-- Glow Effect
local GlowEffect = Instance.new("ImageLabel")
GlowEffect.Name = "Glow"
GlowEffect.Size = UDim2.new(1, 100, 1, 100)
GlowEffect.Position = UDim2.new(0.5, 0, 0.5, 0)
GlowEffect.AnchorPoint = Vector2.new(0.5, 0.5)
GlowEffect.BackgroundTransparency = 1
GlowEffect.Image = "rbxassetid://5554236805"
GlowEffect.ImageColor3 = CurrentTheme.Glow
GlowEffect.ImageTransparency = 0.85
GlowEffect.ScaleType = Enum.ScaleType.Slice
GlowEffect.SliceCenter = Rect.new(23, 23, 277, 277)
GlowEffect.ZIndex = -1
GlowEffect.Parent = MainFrame

-- Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 60, 1, 60)
Shadow.Position = UDim2.new(0.5, 0, 0.5, 5)
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://5554236805"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
Shadow.ZIndex = -2
Shadow.Parent = MainFrame

-- === Title Bar ===
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 52)
TitleBar.BackgroundColor3 = CurrentTheme.Secondary
TitleBar.BackgroundTransparency = 0.3
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 16)
TitleCorner.Parent = TitleBar

local TitleCover = Instance.new("Frame")
TitleCover.Size = UDim2.new(1, 0, 0.5, 0)
TitleCover.Position = UDim2.new(0, 0, 0.5, 0)
TitleCover.BackgroundColor3 = CurrentTheme.Secondary
TitleCover.BackgroundTransparency = 0.3
TitleCover.BorderSizePixel = 0
TitleCover.Parent = TitleBar

-- Animated Logo
local LogoContainer = Instance.new("Frame")
LogoContainer.Size = UDim2.new(0, 40, 0, 40)
LogoContainer.Position = UDim2.new(0, 12, 0.5, 0)
LogoContainer.AnchorPoint = Vector2.new(0, 0.5)
LogoContainer.BackgroundColor3 = CurrentTheme.Accent
LogoContainer.Parent = TitleBar

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 10)
LogoCorner.Parent = LogoContainer

local LogoGradient = Instance.new("UIGradient")
LogoGradient.Color = CurrentTheme.AccentGradient
LogoGradient.Rotation = 45
LogoGradient.Parent = LogoContainer

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(1, 0, 1, 0)
Logo.BackgroundTransparency = 1
Logo.Text = "⚡"
Logo.TextSize = 22
Logo.Parent = LogoContainer

-- Animate logo gradient
task.spawn(function()
    while LogoGradient.Parent do
        for i = 0, 360, 2 do
            if not LogoGradient.Parent then break end
            LogoGradient.Rotation = i
            task.wait(0.03)
        end
    end
end)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 180, 0, 22)
TitleText.Position = UDim2.new(0, 60, 0, 10)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Private Server HUB"
TitleText.TextColor3 = CurrentTheme.Text
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Font = Enum.Font.GothamBlack
TitleText.TextSize = 17
TitleText.Parent = TitleBar

local SubtitleText = Instance.new("TextLabel")
SubtitleText.Size = UDim2.new(0, 180, 0, 16)
SubtitleText.Position = UDim2.new(0, 60, 0, 30)
SubtitleText.BackgroundTransparency = 1
SubtitleText.Text = "by ADMC • v"..Config.Version
SubtitleText.TextColor3 = CurrentTheme.TextDim
SubtitleText.TextXAlignment = Enum.TextXAlignment.Left
SubtitleText.Font = Enum.Font.Gotham
SubtitleText.TextSize = 11
SubtitleText.Parent = TitleBar

-- Status Indicator
local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(0, 240, 0, 22)
StatusDot.BackgroundColor3 = CurrentTheme.Success
StatusDot.Parent = TitleBar

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(1, 0)
StatusCorner.Parent = StatusDot

-- Pulse animation for status
task.spawn(function()
    while StatusDot.Parent do
        tween(StatusDot, {BackgroundTransparency = 0.5}, 0.8)
        task.wait(0.8)
        tween(StatusDot, {BackgroundTransparency = 0}, 0.8)
        task.wait(0.8)
    end
end)

-- Quick Actions Bar
local QuickActionsBar = Instance.new("Frame")
QuickActionsBar.Size = UDim2.new(0, 160, 0, 36)
QuickActionsBar.Position = UDim2.new(1, -280, 0.5, 0)
QuickActionsBar.AnchorPoint = Vector2.new(0, 0.5)
QuickActionsBar.BackgroundColor3 = CurrentTheme.Tertiary
QuickActionsBar.BackgroundTransparency = 0.5
QuickActionsBar.Parent = TitleBar

local QuickActionsCorner = Instance.new("UICorner")
QuickActionsCorner.CornerRadius = UDim.new(0, 8)
QuickActionsCorner.Parent = QuickActionsBar

local QuickActionsLayout = Instance.new("UIListLayout")
QuickActionsLayout.FillDirection = Enum.FillDirection.Horizontal
QuickActionsLayout.Padding = UDim.new(0, 4)
QuickActionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
QuickActionsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
QuickActionsLayout.Parent = QuickActionsBar

local function createQuickAction(icon, tooltip, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 32, 0, 28)
    Btn.BackgroundColor3 = CurrentTheme.Tertiary
    Btn.BackgroundTransparency = 1
    Btn.Text = icon
    Btn.TextSize = 16
    Btn.Parent = QuickActionsBar
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Btn
    
    Btn.MouseEnter:Connect(function()
        tween(Btn, {BackgroundTransparency = 0.3}, 0.2)
    end)
    
    Btn.MouseLeave:Connect(function()
        tween(Btn, {BackgroundTransparency = 1}, 0.2)
    end)
    
    Btn.MouseButton1Click:Connect(callback)
    
    return Btn
end

createQuickAction("🔄", "Refresh", function()
    notify("Refreshed", "Data reloaded successfully", "Success")
    saveData()
end)

createQuickAction("📋", "Copy Last Code", function()
    -- Will be updated with last code
    notify("Clipboard", "No code generated yet", "Info")
end)

createQuickAction("⏯️", "Toggle Anti-AFK", function()
    Config.AntiAFK = not Config.AntiAFK
    Data.Settings.AntiAFK = Config.AntiAFK
    saveData()
    notify("Anti-AFK", Config.AntiAFK and "Enabled" or "Disabled", Config.AntiAFK and "Success" or "Warning")
end)

createQuickAction("🎲", "Random Favorite", function()
    local favList = {}
    for id, data in pairs(Data.Favorites) do
        table.insert(favList, {id = id, data = data})
    end
    if #favList > 0 then
        local random = favList[math.random(1, #favList)]
        local code = generateCode(random.data.PlaceId)
        notify("Random Join", "Joining "..random.data.Name, "Info")
        pcall(function()
            RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(random.data.PlaceId, "", code)
        end)
    else
        notify("No Favorites", "Add some favorites first!", "Warning")
    end
end)

-- Window Controls
local WindowControls = Instance.new("Frame")
WindowControls.Size = UDim2.new(0, 100, 0, 36)
WindowControls.Position = UDim2.new(1, -110, 0.5, 0)
WindowControls.AnchorPoint = Vector2.new(0, 0.5)
WindowControls.BackgroundTransparency = 1
WindowControls.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 36, 0, 36)
MinimizeBtn.Position = UDim2.new(0, 0, 0, 0)
MinimizeBtn.BackgroundColor3 = CurrentTheme.Tertiary
MinimizeBtn.BackgroundTransparency = 0.5
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = CurrentTheme.TextDim
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 16
MinimizeBtn.Parent = WindowControls

local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 8)
MinBtnCorner.Parent = MinimizeBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(0, 56, 0, 0)
CloseBtn.BackgroundColor3 = CurrentTheme.Error
CloseBtn.BackgroundTransparency = 0.2
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = WindowControls

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 8)
CloseBtnCorner.Parent = CloseBtn

-- Hover effects for window controls
MinimizeBtn.MouseEnter:Connect(function()
    tween(MinimizeBtn, {BackgroundTransparency = 0}, 0.2)
end)
MinimizeBtn.MouseLeave:Connect(function()
    tween(MinimizeBtn, {BackgroundTransparency = 0.5}, 0.2)
end)

CloseBtn.MouseEnter:Connect(function()
    tween(CloseBtn, {BackgroundTransparency = 0, Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 55, 0, -1)}, 0.2)
end)
CloseBtn.MouseLeave:Connect(function()
    tween(CloseBtn, {BackgroundTransparency = 0.2, Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0, 56, 0, 0)}, 0.2)
end)

-- === Sidebar Navigation ===
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 70, 1, -62)
Sidebar.Position = UDim2.new(0, 5, 0, 57)
Sidebar.BackgroundColor3 = CurrentTheme.Secondary
Sidebar.BackgroundTransparency = 0.5
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 12)
SidebarCorner.Parent = Sidebar

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 8)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 10)
SidebarPadding.Parent = Sidebar

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -90, 1, -62)
ContentArea.Position = UDim2.new(0, 80, 0, 57)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.Parent = MainFrame

-- === Tab System ===
local Tabs = {}
local CurrentTab = nil
local TabIndicator = nil

local function createNavButton(name, icon, order)
    local NavBtn = Instance.new("TextButton")
    NavBtn.Name = name
    NavBtn.Size = UDim2.new(0, 54, 0, 54)
    NavBtn.BackgroundColor3 = CurrentTheme.Accent
    NavBtn.BackgroundTransparency = 1
    NavBtn.Text = ""
    NavBtn.LayoutOrder = order
    NavBtn.Parent = Sidebar
    
    local NavCorner = Instance.new("UICorner")
    NavCorner.CornerRadius = UDim.new(0, 12)
    NavCorner.Parent = NavBtn
    
    local NavIcon = Instance.new("TextLabel")
    NavIcon.Size = UDim2.new(1, 0, 0, 28)
    NavIcon.Position = UDim2.new(0, 0, 0, 6)
    NavIcon.BackgroundTransparency = 1
    NavIcon.Text = icon
    NavIcon.TextSize = 22
    NavIcon.Parent = NavBtn
    
    local NavLabel = Instance.new("TextLabel")
    NavLabel.Size = UDim2.new(1, 0, 0, 14)
    NavLabel.Position = UDim2.new(0, 0, 1, -16)
    NavLabel.BackgroundTransparency = 1
    NavLabel.Text = name
    NavLabel.TextColor3 = CurrentTheme.TextMuted
    NavLabel.Font = Enum.Font.GothamSemibold
    NavLabel.TextSize = 9
    NavLabel.Parent = NavBtn
    
    -- Content Frame
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = name.."Content"
    ContentFrame.Size = UDim2.new(1, 0, 1, 0)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ScrollBarThickness = 4
    ContentFrame.ScrollBarImageColor3 = CurrentTheme.Accent
    ContentFrame.ScrollBarImageTransparency = 0.3
    ContentFrame.Visible = false
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.Parent = ContentArea
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Name = "UIListLayout"
    ContentLayout.Padding = UDim.new(0, 12)
    ContentLayout.Parent = ContentFrame
    
    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingTop = UDim.new(0, 5)
    ContentPadding.PaddingRight = UDim.new(0, 12)
    ContentPadding.PaddingBottom = UDim.new(0, 20)
    ContentPadding.Parent = ContentFrame
    
    -- Auto-resize canvas
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 30)
    end)
    
    Tabs[name] = {
        Button = NavBtn,
        Content = ContentFrame,
        Icon = NavIcon,
        Label = NavLabel
    }
    
    NavBtn.MouseButton1Click:Connect(function()
        if CurrentTab == name then return end
        
        -- Deselect previous
        if CurrentTab and Tabs[CurrentTab] then
            Tabs[CurrentTab].Content.Visible = false
            tween(Tabs[CurrentTab].Button, {BackgroundTransparency = 1}, 0.25)
            Tabs[CurrentTab].Label.TextColor3 = CurrentTheme.TextMuted
        end
        
        -- Select new
        CurrentTab = name
        ContentFrame.Visible = true
        springTween(NavBtn, {BackgroundTransparency = 0}, 0.3)
        NavLabel.TextColor3 = CurrentTheme.Text
        
        playSound("click")
    end)
    
    NavBtn.MouseEnter:Connect(function()
        if CurrentTab ~= name then
            tween(NavBtn, {BackgroundTransparency = 0.7}, 0.2)
        end
        tween(NavIcon, {Position = UDim2.new(0, 0, 0, 3)}, 0.2)
    end)
    
    NavBtn.MouseLeave:Connect(function()
        if CurrentTab ~= name then
            tween(NavBtn, {BackgroundTransparency = 1}, 0.2)
        end
        tween(NavIcon, {Position = UDim2.new(0, 0, 0, 6)}, 0.2)
    end)
    
    return ContentFrame
end

-- Create Navigation Tabs
local DashboardTab = createNavButton("Home", "🏠", 1)
local JoinTab = createNavButton("Join", "🚀", 2)
local FavoritesTab = createNavButton("Favs", "⭐", 3)
local QueueTab = createNavButton("Queue", "📋", 4)
local HistoryTab = createNavButton("History", "📜", 5)
local SettingsTab = createNavButton("Settings", "⚙️", 6)

-- Select first tab
Tabs["Home"].Button.BackgroundTransparency = 0
Tabs["Home"].Content.Visible = true
Tabs["Home"].Label.TextColor3 = CurrentTheme.Text
CurrentTab = "Home"

-- === UI Component Helpers ===
local function createSection(parent, title, icon)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, 0, 0, 0)
    Section.AutomaticSize = Enum.AutomaticSize.Y
    Section.BackgroundTransparency = 1
    Section.Parent = parent
    
    local SectionHeader = Instance.new("TextLabel")
    SectionHeader.Size = UDim2.new(1, 0, 0, 28)
    SectionHeader.BackgroundTransparency = 1
    SectionHeader.Text = (icon and icon.." " or "")..title
    SectionHeader.TextColor3 = CurrentTheme.Text
    SectionHeader.TextXAlignment = Enum.TextXAlignment.Left
    SectionHeader.Font = Enum.Font.GothamBold
    SectionHeader.TextSize = 15
    SectionHeader.Parent = Section
    
    local SectionContent = Instance.new("Frame")
    SectionContent.Name = "Content"
    SectionContent.Size = UDim2.new(1, 0, 0, 0)
    SectionContent.Position = UDim2.new(0, 0, 0, 32)
    SectionContent.AutomaticSize = Enum.AutomaticSize.Y
    SectionContent.BackgroundTransparency = 1
    SectionContent.Parent = Section
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 10)
    ContentLayout.Parent = SectionContent
    
    return SectionContent
end

local function createCard(parent, title, value, icon, color)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(0, 125, 0, 90)
    Card.BackgroundColor3 = CurrentTheme.Secondary
    Card.BorderSizePixel = 0
    Card.Parent = parent
    
    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 12)
    CardCorner.Parent = Card
    
    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = CurrentTheme.Border
    CardStroke.Thickness = 1
    CardStroke.Transparency = 0.5
    CardStroke.Parent = Card
    
    local IconBg = Instance.new("Frame")
    IconBg.Size = UDim2.new(0, 36, 0, 36)
    IconBg.Position = UDim2.new(0, 12, 0, 12)
    IconBg.BackgroundColor3 = color or CurrentTheme.Accent
    IconBg.BackgroundTransparency = 0.8
    IconBg.Parent = Card
    
    local IconBgCorner = Instance.new("UICorner")
    IconBgCorner.CornerRadius = UDim.new(0, 8)
    IconBgCorner.Parent = IconBg
    
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Size = UDim2.new(1, 0, 1, 0)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Text = icon
    IconLabel.TextSize = 18
    IconLabel.Parent = IconBg
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(1, -24, 0, 24)
    ValueLabel.Position = UDim2.new(0, 12, 0, 52)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(value)
    ValueLabel.TextColor3 = CurrentTheme.Text
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextSize = 18
    ValueLabel.Parent = Card
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -24, 0, 14)
    TitleLabel.Position = UDim2.new(0, 12, 0, 72)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = CurrentTheme.TextDim
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Font = Enum.Font.Gotham
    TitleLabel.TextSize = 11
    TitleLabel.Parent = Card
    
    return Card, ValueLabel
end

local function createInputBox(parent, placeholder, icon)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 50)
    Container.BackgroundColor3 = CurrentTheme.Secondary
    Container.BorderSizePixel = 0
    Container.Parent = parent
    
    local ContainerCorner = Instance.new("UICorner")
    ContainerCorner.CornerRadius = UDim.new(0, 10)
    ContainerCorner.Parent = Container
    
    local ContainerStroke = Instance.new("UIStroke")
    ContainerStroke.Color = CurrentTheme.Border
    ContainerStroke.Thickness = 1
    ContainerStroke.Transparency = 0.5
    ContainerStroke.Parent = Container
    
    if icon then
        local IconLabel = Instance.new("TextLabel")
        IconLabel.Size = UDim2.new(0, 40, 1, 0)
        IconLabel.BackgroundTransparency = 1
        IconLabel.Text = icon
        IconLabel.TextSize = 18
        IconLabel.Parent = Container
    end
    
    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, icon and -50 or -24, 1, 0)
    Input.Position = UDim2.new(0, icon and 40 or 12, 0, 0)
    Input.BackgroundTransparency = 1
    Input.PlaceholderText = placeholder
    Input.PlaceholderColor3 = CurrentTheme.TextMuted
    Input.Text = ""
    Input.TextColor3 = CurrentTheme.Text
    Input.TextXAlignment = Enum.TextXAlignment.Left
    Input.Font = Enum.Font.GothamSemibold
    Input.TextSize = 14
    Input.ClearTextOnFocus = false
    Input.Parent = Container
    
    -- Focus effects
    Input.Focused:Connect(function()
        tween(ContainerStroke, {Color = CurrentTheme.Accent, Transparency = 0}, 0.2)
    end)
    
    Input.FocusLost:Connect(function()
        tween(ContainerStroke, {Color = CurrentTheme.Border, Transparency = 0.5}, 0.2)
    end)
    
    return Input, Container
end

local function createButton(parent, text, color, size, icon)
    local Button = Instance.new("TextButton")
    Button.Size = size or UDim2.new(1, 0, 0, 48)
    Button.BackgroundColor3 = color or CurrentTheme.Accent
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = parent
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 10)
    BtnCorner.Parent = Button
    
    local BtnGradient = Instance.new("UIGradient")
    BtnGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 0.15)
    })
    BtnGradient.Rotation = 90
    BtnGradient.Parent = Button
    
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, 0, 1, 0)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = Button
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.FillDirection = Enum.FillDirection.Horizontal
    ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ContentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ContentLayout.Padding = UDim.new(0, 8)
    ContentLayout.Parent = ContentContainer
    
    if icon then
        local IconLabel = Instance.new("TextLabel")
        IconLabel.Size = UDim2.new(0, 22, 0, 22)
        IconLabel.BackgroundTransparency = 1
        IconLabel.Text = icon
        IconLabel.TextSize = 16
        IconLabel.Parent = ContentContainer
    end
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(0, 0, 0, 22)
    TextLabel.AutomaticSize = Enum.AutomaticSize.X
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = text
    TextLabel.TextColor3 = Color3.new(1, 1, 1)
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.TextSize = 14
    TextLabel.Parent = ContentContainer
    
    -- Ripple effect on click
    Button.MouseButton1Click:Connect(function()
        local Ripple = Instance.new("Frame")
        Ripple.Size = UDim2.new(0, 0, 0, 0)
        Ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
        Ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        Ripple.BackgroundColor3 = Color3.new(1, 1, 1)
        Ripple.BackgroundTransparency = 0.7
        Ripple.Parent = Button
        
        local RippleCorner = Instance.new("UICorner")
        RippleCorner.CornerRadius = UDim.new(1, 0)
        RippleCorner.Parent = Ripple
        
        local size = math.max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 2
        tween(Ripple, {Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1}, 0.5)
        task.delay(0.5, function()
            Ripple:Destroy()
        end)
        
        playSound("click")
    end)
    
    -- Hover effect
    Button.MouseEnter:Connect(function()
        tween(Button, {BackgroundColor3 = Color3.new(
            math.clamp(color.R * 1.15, 0, 1),
            math.clamp(color.G * 1.15, 0, 1),
            math.clamp(color.B * 1.15, 0, 1)
        )}, 0.2)
    end)
    
    Button.MouseLeave:Connect(function()
        tween(Button, {BackgroundColor3 = color}, 0.2)
    end)
    
    return Button, TextLabel
end

local function createToggle(parent, text, default, callback, description)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, description and 65 or 50)
    ToggleFrame.BackgroundColor3 = CurrentTheme.Secondary
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = parent
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 10)
    ToggleCorner.Parent = ToggleFrame
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(1, -80, 0, 22)
    ToggleLabel.Position = UDim2.new(0, 14, 0, description and 10 or 14)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = text
    ToggleLabel.TextColor3 = CurrentTheme.Text
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Font = Enum.Font.GothamSemibold
    ToggleLabel.TextSize = 13
    ToggleLabel.Parent = ToggleFrame
    
    if description then
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(1, -80, 0, 18)
        DescLabel.Position = UDim2.new(0, 14, 0, 32)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = description
        DescLabel.TextColor3 = CurrentTheme.TextMuted
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextSize = 11
        DescLabel.Parent = ToggleFrame
    end
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 52, 0, 28)
    ToggleBtn.Position = UDim2.new(1, -66, 0.5, 0)
    ToggleBtn.AnchorPoint = Vector2.new(0, 0.5)
    ToggleBtn.BackgroundColor3 = default and CurrentTheme.Success or CurrentTheme.Tertiary
    ToggleBtn.Text = ""
    ToggleBtn.Parent = ToggleFrame
    
    local ToggleBtnCorner = Instance.new("UICorner")
    ToggleBtnCorner.CornerRadius = UDim.new(1, 0)
    ToggleBtnCorner.Parent = ToggleBtn
    
    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Size = UDim2.new(0, 22, 0, 22)
    ToggleCircle.Position = default and UDim2.new(1, -25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    ToggleCircle.AnchorPoint = Vector2.new(0, 0.5)
    ToggleCircle.BackgroundColor3 = Color3.new(1, 1, 1)
    ToggleCircle.Parent = ToggleBtn
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = ToggleCircle
    
    -- Shadow on circle
    local CircleShadow = Instance.new("ImageLabel")
    CircleShadow.Size = UDim2.new(1, 8, 1, 8)
    CircleShadow.Position = UDim2.new(0.5, 0, 0.5, 2)
    CircleShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    CircleShadow.BackgroundTransparency = 1
    CircleShadow.Image = "rbxassetid://5554236805"
    CircleShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    CircleShadow.ImageTransparency = 0.7
    CircleShadow.ScaleType = Enum.ScaleType.Slice
    CircleShadow.SliceCenter = Rect.new(23, 23, 277, 277)
    CircleShadow.ZIndex = -1
    CircleShadow.Parent = ToggleCircle
    
    local state = default
    
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            tween(ToggleBtn, {BackgroundColor3 = CurrentTheme.Success}, 0.25)
            springTween(ToggleCircle, {Position = UDim2.new(1, -25, 0.5, 0)}, 0.3)
        else
            tween(ToggleBtn, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.25)
            springTween(ToggleCircle, {Position = UDim2.new(0, 3, 0.5, 0)}, 0.3)
        end
        callback(state)
        playSound("toggle")
    end)
    
    return ToggleFrame, function(newState)
        state = newState
        if state then
            ToggleBtn.BackgroundColor3 = CurrentTheme.Success
            ToggleCircle.Position = UDim2.new(1, -25, 0.5, 0)
        else
            ToggleBtn.BackgroundColor3 = CurrentTheme.Tertiary
            ToggleCircle.Position = UDim2.new(0, 3, 0.5, 0)
        end
    end
end

-- === DASHBOARD TAB ===
local DashboardSection = createSection(DashboardTab, "Dashboard", "📊")

-- Stats Cards Row
local StatsRow = Instance.new("Frame")
StatsRow.Size = UDim2.new(1, 0, 0, 95)
StatsRow.BackgroundTransparency = 1
StatsRow.Parent = DashboardSection

local StatsLayout = Instance.new("UIListLayout")
StatsLayout.FillDirection = Enum.FillDirection.Horizontal
StatsLayout.Padding = UDim.new(0, 12)
StatsLayout.Parent = StatsRow

local _, TotalJoinsLabel = createCard(StatsRow, "Total Joins", Data.Stats.TotalJoins, "🚀", CurrentTheme.Accent)
local _, FavoritesCountLabel = createCard(StatsRow, "Favorites", 0, "⭐", CurrentTheme.Warning)
local _, HistoryCountLabel = createCard(StatsRow, "History", #Data.History, "📜", CurrentTheme.Success)
local _, QueueCountLabel = createCard(StatsRow, "In Queue", #Data.Queue, "📋", CurrentTheme.AccentSecondary)

-- Update favorites count
local favCount = 0
for _ in pairs(Data.Favorites) do favCount = favCount + 1 end
FavoritesCountLabel.Text = tostring(favCount)

-- Quick Join Section
local QuickJoinSection = createSection(DashboardTab, "Quick Join", "⚡")

local QuickJoinInput, _ = createInputBox(QuickJoinSection, "Enter PlaceId or Game URL...", "🔗")

local QuickJoinBtn, _ = createButton(QuickJoinSection, "Quick Join", CurrentTheme.Accent, UDim2.new(1, 0, 0, 48), "🚀")

QuickJoinBtn.MouseButton1Click:Connect(function()
    local input = QuickJoinInput.Text
    local placeId = parseGameUrl(input) or tonumber(input)
    
    if placeId and placeId > 0 then
        local code = generateCode(placeId)
        local gameName = getGameName(placeId)
        addToHistory(placeId, gameName)
        TotalJoinsLabel.Text = tostring(Data.Stats.TotalJoins)
        
        notify("Teleporting", "Joining private server for "..gameName, "Info")
        
        pcall(function()
            RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(placeId, "", code)
        end)
    else
        notify("Error", "Invalid PlaceId or URL", "Error")
    end
end)

-- Recent Activity Section
local RecentSection = createSection(DashboardTab, "Recent Activity", "🕐")

local function createRecentEntry(entry)
    local Entry = Instance.new("Frame")
    Entry.Size = UDim2.new(1, 0, 0, 56)
    Entry.BackgroundColor3 = CurrentTheme.Secondary
    Entry.BorderSizePixel = 0
    Entry.Parent = RecentSection
    
    local EntryCorner = Instance.new("UICorner")
    EntryCorner.CornerRadius = UDim.new(0, 10)
    EntryCorner.Parent = Entry
    
    -- Thumbnail
    if Data.Settings.ShowThumbnails then
        local Thumb = Instance.new("ImageLabel")
        Thumb.Size = UDim2.new(0, 44, 0, 44)
        Thumb.Position = UDim2.new(0, 6, 0.5, 0)
        Thumb.AnchorPoint = Vector2.new(0, 0.5)
        Thumb.BackgroundColor3 = CurrentTheme.Tertiary
        Thumb.Image = getGameThumbnail(entry.PlaceId)
        Thumb.Parent = Entry
        
        local ThumbCorner = Instance.new("UICorner")
        ThumbCorner.CornerRadius = UDim.new(0, 8)
        ThumbCorner.Parent = Thumb
    end
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -120, 0, 20)
    NameLabel.Position = UDim2.new(0, Data.Settings.ShowThumbnails and 58 or 12, 0, 10)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = entry.Name
    NameLabel.TextColor3 = CurrentTheme.Text
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Font = Enum.Font.GothamSemibold
    NameLabel.TextSize = 13
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = Entry
    
    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Size = UDim2.new(1, -120, 0, 16)
    TimeLabel.Position = UDim2.new(0, Data.Settings.ShowThumbnails and 58 or 12, 0, 30)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.Text = formatTime(entry.Time)
    TimeLabel.TextColor3 = CurrentTheme.TextMuted
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
    TimeLabel.Font = Enum.Font.Gotham
    TimeLabel.TextSize = 11
    TimeLabel.Parent = Entry
    
    local JoinBtn = Instance.new("TextButton")
    JoinBtn.Size = UDim2.new(0, 44, 0, 36)
    JoinBtn.Position = UDim2.new(1, -56, 0.5, 0)
    JoinBtn.AnchorPoint = Vector2.new(0, 0.5)
    JoinBtn.BackgroundColor3 = CurrentTheme.Accent
    JoinBtn.Text = "🚀"
    JoinBtn.TextSize = 18
    JoinBtn.Parent = Entry
    
    local JoinCorner = Instance.new("UICorner")
    JoinCorner.CornerRadius = UDim.new(0, 8)
    JoinCorner.Parent = JoinBtn
    
    JoinBtn.MouseButton1Click:Connect(function()
        local code = generateCode(entry.PlaceId)
        notify("Teleporting", "Rejoining "..entry.Name, "Info")
        pcall(function()
            RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(entry.PlaceId, "", code)
        end)
    end)
    
    return Entry
end

-- Show last 3 entries
for i = 1, math.min(3, #Data.History) do
    createRecentEntry(Data.History[i])
end

-- === JOIN TAB ===
local JoinSection = createSection(JoinTab, "Join Private Server", "🎮")

local PlaceIdInput, PlaceIdContainer = createInputBox(JoinSection, "Enter PlaceId or paste game URL...", "🎮")

-- Game Preview
local GamePreview = Instance.new("Frame")
GamePreview.Size = UDim2.new(1, 0, 0, 80)
GamePreview.BackgroundColor3 = CurrentTheme.Secondary
GamePreview.BorderSizePixel = 0
GamePreview.Visible = false
GamePreview.Parent = JoinSection

local PreviewCorner = Instance.new("UICorner")
PreviewCorner.CornerRadius = UDim.new(0, 12)
PreviewCorner.Parent = GamePreview

local PreviewThumbnail = Instance.new("ImageLabel")
PreviewThumbnail.Size = UDim2.new(0, 64, 0, 64)
PreviewThumbnail.Position = UDim2.new(0, 8, 0.5, 0)
PreviewThumbnail.AnchorPoint = Vector2.new(0, 0.5)
PreviewThumbnail.BackgroundColor3 = CurrentTheme.Tertiary
PreviewThumbnail.Parent = GamePreview

local PreviewThumbCorner = Instance.new("UICorner")
PreviewThumbCorner.CornerRadius = UDim.new(0, 10)
PreviewThumbCorner.Parent = PreviewThumbnail

local PreviewName = Instance.new("TextLabel")
PreviewName.Size = UDim2.new(1, -100, 0, 24)
PreviewName.Position = UDim2.new(0, 82, 0, 16)
PreviewName.BackgroundTransparency = 1
PreviewName.Text = "Loading..."
PreviewName.TextColor3 = CurrentTheme.Text
PreviewName.TextXAlignment = Enum.TextXAlignment.Left
PreviewName.Font = Enum.Font.GothamBold
PreviewName.TextSize = 15
PreviewName.TextTruncate = Enum.TextTruncate.AtEnd
PreviewName.Parent = GamePreview

local PreviewId = Instance.new("TextLabel")
PreviewId.Size = UDim2.new(1, -100, 0, 18)
PreviewId.Position = UDim2.new(0, 82, 0, 42)
PreviewId.BackgroundTransparency = 1
PreviewId.Text = "PlaceId: ..."
PreviewId.TextColor3 = CurrentTheme.TextDim
PreviewId.TextXAlignment = Enum.TextXAlignment.Left
PreviewId.Font = Enum.Font.Gotham
PreviewId.TextSize = 12
PreviewId.Parent = GamePreview

-- Update preview on input change
PlaceIdInput:GetPropertyChangedSignal("Text"):Connect(function()
    local input = PlaceIdInput.Text
    local placeId = parseGameUrl(input) or tonumber(input)
    
    if placeId and placeId > 0 then
        GamePreview.Visible = true
        PreviewName.Text = "Loading..."
        PreviewId.Text = "PlaceId: "..formatNumber(placeId)
        PreviewThumbnail.Image = getGameThumbnail(placeId)
        
        task.spawn(function()
            local name = getGameName(placeId)
            local currentId = parseGameUrl(PlaceIdInput.Text) or tonumber(PlaceIdInput.Text)
            if currentId == placeId then
                PreviewName.Text = name
            end
        end)
    else
        GamePreview.Visible = false
    end
end)

-- Action Buttons Row
local ActionRow = Instance.new("Frame")
ActionRow.Size = UDim2.new(1, 0, 0, 50)
ActionRow.BackgroundTransparency = 1
ActionRow.Parent = JoinSection

local ActionLayout = Instance.new("UIListLayout")
ActionLayout.FillDirection = Enum.FillDirection.Horizontal
ActionLayout.Padding = UDim.new(0, 12)
ActionLayout.Parent = ActionRow

local JoinButton, JoinBtnLabel = createButton(ActionRow, "Generate & Join", CurrentTheme.Accent, UDim2.new(0.55, -6, 1, 0), "🚀")
local SaveButton, _ = createButton(ActionRow, "Save", CurrentTheme.Success, UDim2.new(0.25, -6, 1, 0), "⭐")
local QueueButton, _ = createButton(ActionRow, "Queue", CurrentTheme.AccentSecondary, UDim2.new(0.2, -6, 1, 0), "📋")

-- Code Display Section
local CodeSection = createSection(JoinTab, "Generated Access Code", "🔐")

local CodeDisplay = Instance.new("Frame")
CodeDisplay.Size = UDim2.new(1, 0, 0, 100)
CodeDisplay.BackgroundColor3 = CurrentTheme.Secondary
CodeDisplay.BorderSizePixel = 0
CodeDisplay.Parent = CodeSection

local CodeCorner = Instance.new("UICorner")
CodeCorner.CornerRadius = UDim.new(0, 12)
CodeCorner.Parent = CodeDisplay

local CodeText = Instance.new("TextLabel")
CodeText.Size = UDim2.new(1, -70, 1, -16)
CodeText.Position = UDim2.new(0, 14, 0, 8)
CodeText.BackgroundTransparency = 1
CodeText.Text = "Code will appear here after generation..."
CodeText.TextColor3 = CurrentTheme.TextMuted
CodeText.TextXAlignment = Enum.TextXAlignment.Left
CodeText.TextYAlignment = Enum.TextYAlignment.Top
CodeText.Font = Enum.Font.Code
CodeText.TextSize = 11
CodeText.TextWrapped = true
CodeText.Parent = CodeDisplay

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 48, 0, 48)
CopyBtn.Position = UDim2.new(1, -60, 0.5, 0)
CopyBtn.AnchorPoint = Vector2.new(0, 0.5)
CopyBtn.BackgroundColor3 = CurrentTheme.Tertiary
CopyBtn.Text = "📋"
CopyBtn.TextSize = 22
CopyBtn.Parent = CodeDisplay

local CopyBtnCorner = Instance.new("UICorner")
CopyBtnCorner.CornerRadius = UDim.new(0, 10)
CopyBtnCorner.Parent = CopyBtn

local LastGeneratedCode = ""
local LastPlaceId = 0

-- Join Button Logic
JoinButton.MouseButton1Click:Connect(function()
    local input = PlaceIdInput.Text
    local placeId = parseGameUrl(input) or tonumber(input)
    
    if placeId and placeId > 0 then
        JoinBtnLabel.Text = "Generating..."
        
        local code = generateCode(placeId)
        LastGeneratedCode = code
        LastPlaceId = placeId
        CodeText.Text = code
        CodeText.TextColor3 = CurrentTheme.Text
        
        if setclipboard then
            setclipboard(code.."\n"..tostring(placeId))
        end
        
        local gameName = getGameName(placeId)
        addToHistory(placeId, gameName)
        TotalJoinsLabel.Text = tostring(Data.Stats.TotalJoins)
        
        JoinBtnLabel.Text = "Teleporting..."
        notify("Teleporting", "Joining private server for "..gameName, "Info")
        
        pcall(function()
            RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(placeId, "", code)
        end)
        
        task.wait(2)
        JoinBtnLabel.Text = "Generate & Join"
    else
        notify("Error", "Please enter a valid PlaceId or URL", "Error")
    end
end)

-- Save to Favorites
SaveButton.MouseButton1Click:Connect(function()
    local input = PlaceIdInput.Text
    local placeId = parseGameUrl(input) or tonumber(input)
    
    if placeId and placeId > 0 then
        local gameName = getGameName(placeId)
        Data.Favorites[tostring(placeId)] = {
            Name = gameName,
            PlaceId = placeId,
            Category = "All",
            Added = os.time(),
            Notes = ""
        }
        saveData()
        
        local count = 0
        for _ in pairs(Data.Favorites) do count = count + 1 end
        FavoritesCountLabel.Text = tostring(count)
        
        notify("Saved", gameName.." added to favorites!", "Success")
    else
        notify("Error", "Enter a valid PlaceId first", "Error")
    end
end)

-- Add to Queue
QueueButton.MouseButton1Click:Connect(function()
    local input = PlaceIdInput.Text
    local placeId = parseGameUrl(input) or tonumber(input)
    
    if placeId and placeId > 0 then
        if #Data.Queue >= Config.MaxQueue then
            notify("Queue Full", "Maximum "..Config.MaxQueue.." items in queue", "Warning")
            return
        end
        
        local gameName = getGameName(placeId)
        table.insert(Data.Queue, {
            PlaceId = placeId,
            Name = gameName,
            Added = os.time()
        })
        saveData()
        QueueCountLabel.Text = tostring(#Data.Queue)
        notify("Queued", gameName.." added to queue", "Success")
    else
        notify("Error", "Enter a valid PlaceId first", "Error")
    end
end)

-- Copy Button
CopyBtn.MouseButton1Click:Connect(function()
    if LastGeneratedCode ~= "" then
        if setclipboard then
            setclipboard(LastGeneratedCode)
        end
        notify("Copied", "Access code copied to clipboard!", "Success")
    else
        notify("Error", "No code generated yet", "Warning")
    end
end)

CopyBtn.MouseEnter:Connect(function()
    tween(CopyBtn, {BackgroundColor3 = CurrentTheme.Accent}, 0.2)
end)
CopyBtn.MouseLeave:Connect(function()
    tween(CopyBtn, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
end)

-- === FAVORITES TAB ===
local FavHeader = createSection(FavoritesTab, "Saved Servers", "⭐")

-- Category Filter
local CategoryFilter = Instance.new("Frame")
CategoryFilter.Size = UDim2.new(1, 0, 0, 40)
CategoryFilter.BackgroundTransparency = 1
CategoryFilter.Parent = FavHeader

local CategoryLayout = Instance.new("UIListLayout")
CategoryLayout.FillDirection = Enum.FillDirection.Horizontal
CategoryLayout.Padding = UDim.new(0, 8)
CategoryLayout.Parent = CategoryFilter

local SelectedCategory = "All"

local function createCategoryBtn(cat)
    local CatBtn = Instance.new("TextButton")
    CatBtn.Size = UDim2.new(0, 0, 0, 32)
    CatBtn.AutomaticSize = Enum.AutomaticSize.X
    CatBtn.BackgroundColor3 = SelectedCategory == cat.Name and cat.Color or CurrentTheme.Tertiary
    CatBtn.Text = ""
    CatBtn.Parent = CategoryFilter
    
    local CatCorner = Instance.new("UICorner")
    CatCorner.CornerRadius = UDim.new(0, 8)
    CatCorner.Parent = CatBtn
    
    local CatPadding = Instance.new("UIPadding")
    CatPadding.PaddingLeft = UDim.new(0, 12)
    CatPadding.PaddingRight = UDim.new(0, 12)
    CatPadding.Parent = CatBtn
    
    local CatContent = Instance.new("Frame")
    CatContent.Size = UDim2.new(0, 0, 1, 0)
    CatContent.AutomaticSize = Enum.AutomaticSize.X
    CatContent.BackgroundTransparency = 1
    CatContent.Parent = CatBtn
    
    local CatContentLayout = Instance.new("UIListLayout")
    CatContentLayout.FillDirection = Enum.FillDirection.Horizontal
    CatContentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    CatContentLayout.Padding = UDim.new(0, 6)
    CatContentLayout.Parent = CatContent
    
    local CatIcon = Instance.new("TextLabel")
    CatIcon.Size = UDim2.new(0, 18, 0, 18)
    CatIcon.BackgroundTransparency = 1
    CatIcon.Text = cat.Icon
    CatIcon.TextSize = 14
    CatIcon.Parent = CatContent
    
    local CatLabel = Instance.new("TextLabel")
    CatLabel.Size = UDim2.new(0, 0, 0, 18)
    CatLabel.AutomaticSize = Enum.AutomaticSize.X
    CatLabel.BackgroundTransparency = 1
    CatLabel.Text = cat.Name
    CatLabel.TextColor3 = CurrentTheme.Text
    CatLabel.Font = Enum.Font.GothamSemibold
    CatLabel.TextSize = 12
    CatLabel.Parent = CatContent
    
    return CatBtn
end

for _, cat in ipairs(Data.Categories) do
    createCategoryButton(cat)
end

-- Add Category Button
local AddCatBtn = Instance.new("TextButton")
AddCatBtn.Size = UDim2.new(0, 35, 0, 35)
AddCatBtn.BackgroundColor3 = CurrentTheme.Success
AddCatBtn.Text = "+"
AddCatBtn.TextColor3 = Color3.new(1, 1, 1)
AddCatBtn.Font = Enum.Font.GothamBold
AddCatBtn.TextSize = 18
AddCatBtn.Parent = CategoryContainer

local AddCatCorner = Instance.new("UICorner")
AddCatCorner.CornerRadius = UDim.new(0, 8)
AddCatCorner.Parent = AddCatBtn

AddCatBtn.MouseButton1Click:Connect(function()
    -- Popup for new category
    local catName = "Category "..tostring(#Data.Categories + 1)
    table.insert(Data.Categories, {
        Name = catName,
        Icon = "📁",
        Color = CurrentTheme.Accent
    })
    createCategoryButton(Data.Categories[#Data.Categories])
    saveData()
    notify("Category Created", "New category '"..catName.."' added!", "Success")
end)

-- Favorites List Container
local FavScrollFrame = Instance.new("ScrollingFrame")
FavScrollFrame.Size = UDim2.new(1, -10, 0, 220)
FavScrollFrame.BackgroundTransparency = 1
FavScrollFrame.ScrollBarThickness = 4
FavScrollFrame.ScrollBarImageColor3 = CurrentTheme.Accent
FavScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
FavScrollFrame.Parent = FavoritesTab

local FavScrollLayout = Instance.new("UIListLayout")
FavScrollLayout.Padding = UDim.new(0, 8)
FavScrollLayout.Parent = FavScrollFrame

local function createFavoriteCard(id, data)
    local Card = Instance.new("Frame")
    Card.Name = "FavCard_"..id
    Card.Size = UDim2.new(1, 0, 0, 75)
    Card.BackgroundColor3 = CurrentTheme.Secondary
    Card.BorderSizePixel = 0
    Card.Parent = FavScrollFrame
    
    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 10)
    CardCorner.Parent = Card
    
    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = CurrentTheme.Border
    CardStroke.Thickness = 1
    CardStroke.Transparency = 0.5
    CardStroke.Parent = Card
    
    -- Game Icon Placeholder
    local IconHolder = Instance.new("Frame")
    IconHolder.Size = UDim2.new(0, 55, 0, 55)
    IconHolder.Position = UDim2.new(0, 10, 0.5, 0)
    IconHolder.AnchorPoint = Vector2.new(0, 0.5)
    IconHolder.BackgroundColor3 = CurrentTheme.Tertiary
    IconHolder.Parent = Card
    
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 8)
    IconCorner.Parent = IconHolder
    
    local GameIcon = Instance.new("TextLabel")
    GameIcon.Size = UDim2.new(1, 0, 1, 0)
    GameIcon.BackgroundTransparency = 1
    GameIcon.Text = "🎮"
    GameIcon.TextSize = 28
    GameIcon.Parent = IconHolder
    
    -- Game Info
    local GameTitle = Instance.new("TextLabel")
    GameTitle.Size = UDim2.new(1, -180, 0, 22)
    GameTitle.Position = UDim2.new(0, 75, 0, 12)
    GameTitle.BackgroundTransparency = 1
    GameTitle.Text = data.Name or "Unknown Game"
    GameTitle.TextColor3 = CurrentTheme.Text
    GameTitle.TextXAlignment = Enum.TextXAlignment.Left
    GameTitle.Font = Enum.Font.GothamBold
    GameTitle.TextSize = 14
    GameTitle.TextTruncate = Enum.TextTruncate.AtEnd
    GameTitle.Parent = Card
    
    local GameInfo = Instance.new("TextLabel")
    GameInfo.Size = UDim2.new(1, -180, 0, 16)
    GameInfo.Position = UDim2.new(0, 75, 0, 34)
    GameInfo.BackgroundTransparency = 1
    GameInfo.Text = "🆔 "..formatNumber(data.PlaceId).." • 📁 "..(data.Category or "Default")
    GameInfo.TextColor3 = CurrentTheme.TextDim
    GameInfo.TextXAlignment = Enum.TextXAlignment.Left
    GameInfo.Font = Enum.Font.Gotham
    GameInfo.TextSize = 11
    GameInfo.Parent = Card
    
    local LastUsed = Instance.new("TextLabel")
    LastUsed.Size = UDim2.new(1, -180, 0, 14)
    LastUsed.Position = UDim2.new(0, 75, 0, 52)
    LastUsed.BackgroundTransparency = 1
    LastUsed.Text = "⏰ "..formatTime(data.Added or os.time())
    LastUsed.TextColor3 = CurrentTheme.TextDim
    LastUsed.TextXAlignment = Enum.TextXAlignment.Left
    LastUsed.Font = Enum.Font.Gotham
    LastUsed.TextSize = 10
    LastUsed.Parent = Card
    
    -- Action Buttons Container
    local ActionContainer = Instance.new("Frame")
    ActionContainer.Size = UDim2.new(0, 95, 0, 55)
    ActionContainer.Position = UDim2.new(1, -105, 0.5, 0)
    ActionContainer.AnchorPoint = Vector2.new(0, 0.5)
    ActionContainer.BackgroundTransparency = 1
    ActionContainer.Parent = Card
    
    local ActionLayout = Instance.new("UIGridLayout")
    ActionLayout.CellSize = UDim2.new(0, 42, 0, 25)
    ActionLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    ActionLayout.Parent = ActionContainer
    
    -- Join Button
    local JoinBtn = Instance.new("TextButton")
    JoinBtn.BackgroundColor3 = CurrentTheme.Accent
    JoinBtn.Text = "🚀"
    JoinBtn.TextSize = 14
    JoinBtn.Parent = ActionContainer
    
    local JoinCorner = Instance.new("UICorner")
    JoinCorner.CornerRadius = UDim.new(0, 6)
    JoinCorner.Parent = JoinBtn
    
    -- Copy Button
    local CopyBtn = Instance.new("TextButton")
    CopyBtn.BackgroundColor3 = CurrentTheme.Tertiary
    CopyBtn.Text = "📋"
    CopyBtn.TextSize = 14
    CopyBtn.Parent = ActionContainer
    
    local CopyCorner = Instance.new("UICorner")
    CopyCorner.CornerRadius = UDim.new(0, 6)
    CopyCorner.Parent = CopyBtn
    
    -- Edit Button
    local EditBtn = Instance.new("TextButton")
    EditBtn.BackgroundColor3 = CurrentTheme.Warning
    EditBtn.Text = "✏️"
    EditBtn.TextSize = 14
    EditBtn.Parent = ActionContainer
    
    local EditCorner = Instance.new("UICorner")
    EditCorner.CornerRadius = UDim.new(0, 6)
    EditCorner.Parent = EditBtn
    
    -- Delete Button
    local DeleteBtn = Instance.new("TextButton")
    DeleteBtn.BackgroundColor3 = CurrentTheme.Error
    DeleteBtn.Text = "🗑️"
    DeleteBtn.TextSize = 14
    DeleteBtn.Parent = ActionContainer
    
    local DeleteCorner = Instance.new("UICorner")
    DeleteCorner.CornerRadius = UDim.new(0, 6)
    DeleteCorner.Parent = DeleteBtn
    
    -- Button Actions
    JoinBtn.MouseButton1Click:Connect(function()
        JoinBtn.Text = "⏳"
        local code = generateCode(data.PlaceId)
        
        -- Add to queue if enabled
        if Data.Settings.UseQueue then
            addToQueue(data.PlaceId, data.Name, code)
            JoinBtn.Text = "🚀"
            return
        end
        
        notify("Teleporting", "Joining "..data.Name.."...", "Info")
        
        -- Update last used
        data.LastUsed = os.time()
        Data.Favorites[id] = data
        saveData()
        
        pcall(function()
            RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(data.PlaceId, "", code)
        end)
        
        task.wait(1)
        JoinBtn.Text = "🚀"
    end)
    
    CopyBtn.MouseButton1Click:Connect(function()
        local code = generateCode(data.PlaceId)
        if setclipboard then
            setclipboard("PlaceId: "..data.PlaceId.."\nCode: "..code)
            notify("Copied", "Access code copied to clipboard!", "Success")
        end
    end)
    
    EditBtn.MouseButton1Click:Connect(function()
        -- Open edit modal
        openEditModal(id, data)
    end)
    
    DeleteBtn.MouseButton1Click:Connect(function()
        -- Confirmation animation
        if DeleteBtn.Text == "❓" then
            Data.Favorites[id] = nil
            saveData()
            tween(Card, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
            task.wait(0.2)
            Card:Destroy()
            updateFavScrollCanvas()
            notify("Deleted", data.Name.." removed from favorites", "Warning")
        else
            DeleteBtn.Text = "❓"
            task.delay(2, function()
                if DeleteBtn and DeleteBtn.Parent then
                    DeleteBtn.Text = "🗑️"
                end
            end)
        end
    end)
    
    -- Hover Effects
    Card.MouseEnter:Connect(function()
        tween(CardStroke, {Color = CurrentTheme.Accent, Transparency = 0}, 0.2)
        tween(Card, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
    end)
    
    Card.MouseLeave:Connect(function()
        tween(CardStroke, {Color = CurrentTheme.Border, Transparency = 0.5}, 0.2)
        tween(Card, {BackgroundColor3 = CurrentTheme.Secondary}, 0.2)
    end)
    
    return Card
end

local function updateFavScrollCanvas()
    FavScrollFrame.CanvasSize = UDim2.new(0, 0, 0, FavScrollLayout.AbsoluteContentSize.Y + 20)
end

local function refreshFavorites(filter, category)
    -- Clear existing cards
    for _, child in ipairs(FavScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    filter = filter and filter:lower() or ""
    category = category or SelectedCategory
    
    local count = 0
    for id, data in pairs(Data.Favorites) do
        local matchesFilter = filter == "" or 
            (data.Name and data.Name:lower():find(filter)) or 
            tostring(data.PlaceId):find(filter)
        local matchesCategory = category == "All" or data.Category == category
        
        if matchesFilter and matchesCategory then
            createFavoriteCard(id, data)
            count = count + 1
        end
    end
    
    -- Show empty state if no favorites
    if count == 0 then
        local EmptyState = Instance.new("Frame")
        EmptyState.Size = UDim2.new(1, 0, 0, 100)
        EmptyState.BackgroundTransparency = 1
        EmptyState.Parent = FavScrollFrame
        
        local EmptyIcon = Instance.new("TextLabel")
        EmptyIcon.Size = UDim2.new(1, 0, 0, 40)
        EmptyIcon.BackgroundTransparency = 1
        EmptyIcon.Text = "📭"
        EmptyIcon.TextSize = 32
        EmptyIcon.Parent = EmptyState
        
        local EmptyText = Instance.new("TextLabel")
        EmptyText.Size = UDim2.new(1, 0, 0, 25)
        EmptyText.Position = UDim2.new(0, 0, 0, 45)
        EmptyText.BackgroundTransparency = 1
        EmptyText.Text = "No favorites found"
        EmptyText.TextColor3 = CurrentTheme.TextDim
        EmptyText.Font = Enum.Font.GothamSemibold
        EmptyText.TextSize = 14
        EmptyText.Parent = EmptyState
        
        local EmptyHint = Instance.new("TextLabel")
        EmptyHint.Size = UDim2.new(1, 0, 0, 20)
        EmptyHint.Position = UDim2.new(0, 0, 0, 70)
        EmptyHint.BackgroundTransparency = 1
        EmptyHint.Text = "Add games from the Join tab!"
        EmptyHint.TextColor3 = CurrentTheme.TextDim
        EmptyHint.Font = Enum.Font.Gotham
        EmptyHint.TextSize = 12
        EmptyHint.Parent = EmptyState
    end
    
    updateFavScrollCanvas()
end

-- Search functionality
FavSearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    refreshFavorites(FavSearchInput.Text, SelectedCategory)
end)

-- Initial favorites load
task.spawn(function()
    refreshFavorites()
end)

-- === HISTORY TAB CONTENT ===
local HistHeader = Instance.new("TextLabel")
HistHeader.Size = UDim2.new(1, -10, 0, 30)
HistHeader.BackgroundTransparency = 1
HistHeader.Text = "📜 Recent Activity"
HistHeader.TextColor3 = CurrentTheme.Text
HistHeader.TextXAlignment = Enum.TextXAlignment.Left
HistHeader.Font = Enum.Font.GothamBold
HistHeader.TextSize = 16
HistHeader.Parent = HistoryTab

-- History Stats
local HistStats = Instance.new("Frame")
HistStats.Size = UDim2.new(1, -10, 0, 50)
HistStats.BackgroundColor3 = CurrentTheme.Secondary
HistStats.BorderSizePixel = 0
HistStats.Parent = HistoryTab

local HistStatsCorner = Instance.new("UICorner")
HistStatsCorner.CornerRadius = UDim.new(0, 10)
HistStatsCorner.Parent = HistStats

local StatsLayout = Instance.new("UIListLayout")
StatsLayout.FillDirection = Enum.FillDirection.Horizontal
StatsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
StatsLayout.Padding = UDim.new(0, 20)
StatsLayout.Parent = HistStats

local function createStatItem(icon, value, label)
    local StatItem = Instance.new("Frame")
    StatItem.Size = UDim2.new(0, 80, 1, 0)
    StatItem.BackgroundTransparency = 1
    StatItem.Parent = HistStats
    
    local StatIcon = Instance.new("TextLabel")
    StatIcon.Size = UDim2.new(1, 0, 0, 20)
    StatIcon.Position = UDim2.new(0, 0, 0, 5)
    StatIcon.BackgroundTransparency = 1
    StatIcon.Text = icon.." "..tostring(value)
    StatIcon.TextColor3 = CurrentTheme.Text
    StatIcon.Font = Enum.Font.GothamBold
    StatIcon.TextSize = 14
    StatIcon.Parent = StatItem
    
    local StatLabel = Instance.new("TextLabel")
    StatLabel.Size = UDim2.new(1, 0, 0, 15)
    StatLabel.Position = UDim2.new(0, 0, 0, 28)
    StatLabel.BackgroundTransparency = 1
    StatLabel.Text = label
    StatLabel.TextColor3 = CurrentTheme.TextDim
    StatLabel.Font = Enum.Font.Gotham
    StatLabel.TextSize = 10
    StatLabel.Parent = StatItem
    
    return StatItem
end

createStatItem("📊", #Data.History, "Total Joins")
createStatItem("⭐", table.getn(Data.Favorites) or 0, "Favorites")
createStatItem("📁", #Data.Categories, "Categories")

-- History Actions
local HistActionRow = Instance.new("Frame")
HistActionRow.Size = UDim2.new(1, -10, 0, 38)
HistActionRow.BackgroundTransparency = 1
HistActionRow.Parent = HistoryTab

local HistActionLayout = Instance.new("UIListLayout")
HistActionLayout.FillDirection = Enum.FillDirection.Horizontal
HistActionLayout.Padding = UDim.new(0, 8)
HistActionLayout.Parent = HistActionRow

local ClearHistBtn = createButton(HistActionRow, "🗑️ Clear All", CurrentTheme.Error, UDim2.new(0.48, 0, 1, 0))
local ExportHistBtn = createButton(HistActionRow, "📤 Export", CurrentTheme.Tertiary, UDim2.new(0.48, 0, 1, 0))

-- History List
local HistScrollFrame = Instance.new("ScrollingFrame")
HistScrollFrame.Size = UDim2.new(1, -10, 0, 200)
HistScrollFrame.BackgroundTransparency = 1
HistScrollFrame.ScrollBarThickness = 4
HistScrollFrame.ScrollBarImageColor3 = CurrentTheme.Accent
HistScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
HistScrollFrame.Parent = HistoryTab

local HistScrollLayout = Instance.new("UIListLayout")
HistScrollLayout.Padding = UDim.new(0, 6)
HistScrollLayout.Parent = HistScrollFrame

local function createHistoryEntry(entry, index)
    local HistEntry = Instance.new("Frame")
    HistEntry.Name = "HistEntry_"..index
    HistEntry.Size = UDim2.new(1, 0, 0, 55)
    HistEntry.BackgroundColor3 = CurrentTheme.Secondary
    HistEntry.BorderSizePixel = 0
    HistEntry.Parent = HistScrollFrame
    
    local EntryCorner = Instance.new("UICorner")
    EntryCorner.CornerRadius = UDim.new(0, 8)
    EntryCorner.Parent = HistEntry
    
    -- Index Badge
    local IndexBadge = Instance.new("TextLabel")
    IndexBadge.Size = UDim2.new(0, 25, 0, 25)
    IndexBadge.Position = UDim2.new(0, 10, 0.5, 0)
    IndexBadge.AnchorPoint = Vector2.new(0, 0.5)
    IndexBadge.BackgroundColor3 = CurrentTheme.Tertiary
    IndexBadge.Text = tostring(index)
    IndexBadge.TextColor3 = CurrentTheme.TextDim
    IndexBadge.Font = Enum.Font.GothamBold
    IndexBadge.TextSize = 11
    IndexBadge.Parent = HistEntry
    
    local IndexCorner = Instance.new("UICorner")
    IndexCorner.CornerRadius = UDim.new(0, 6)
    IndexCorner.Parent = IndexBadge
    
    -- Entry Info
    local EntryName = Instance.new("TextLabel")
    EntryName.Size = UDim2.new(1, -130, 0, 20)
    EntryName.Position = UDim2.new(0, 45, 0, 10)
    EntryName.BackgroundTransparency = 1
    EntryName.Text = entry.Name or "Unknown"
    EntryName.TextColor3 = CurrentTheme.Text
    EntryName.TextXAlignment = Enum.TextXAlignment.Left
    EntryName.Font = Enum.Font.GothamSemibold
    EntryName.TextSize = 13
    EntryName.TextTruncate = Enum.TextTruncate.AtEnd
    EntryName.Parent = HistEntry
    
    local EntryDetails = Instance.new("TextLabel")
    EntryDetails.Size = UDim2.new(1, -130, 0, 16)
    EntryDetails.Position = UDim2.new(0, 45, 0, 30)
    EntryDetails.BackgroundTransparency = 1
    EntryDetails.Text = "⏰ "..formatTime(entry.Time).." • 🆔 "..formatNumber(entry.PlaceId)
    EntryDetails.TextColor3 = CurrentTheme.TextDim
    EntryDetails.TextXAlignment = Enum.TextXAlignment.Left
    EntryDetails.Font = Enum.Font.Gotham
    EntryDetails.TextSize = 10
    EntryDetails.Parent = HistEntry
    
    -- Rejoin Button
    local RejoinBtn = Instance.new("TextButton")
    RejoinBtn.Size = UDim2.new(0, 50, 0, 35)
    RejoinBtn.Position = UDim2.new(1, -65, 0.5, 0)
    RejoinBtn.AnchorPoint = Vector2.new(0, 0.5)
    RejoinBtn.BackgroundColor3 = CurrentTheme.Accent
    RejoinBtn.Text = "🔄"
    RejoinBtn.TextSize = 16
    RejoinBtn.Parent = HistEntry
    
    local RejoinCorner = Instance.new("UICorner")
    RejoinCorner.CornerRadius = UDim.new(0, 8)
    RejoinCorner.Parent = RejoinBtn
    
    RejoinBtn.MouseButton1Click:Connect(function()
        RejoinBtn.Text = "⏳"
        local code = generateCode(entry.PlaceId)
        notify("Rejoining", "Teleporting to "..entry.Name.."...", "Info")
        
        pcall(function()
            RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(entry.PlaceId, "", code)
        end)
        
        task.wait(1)
        RejoinBtn.Text = "🔄"
    end)
    
    -- Hover effect
    HistEntry.MouseEnter:Connect(function()
        tween(HistEntry, {BackgroundColor3 = CurrentTheme.Tertiary}, 0.2)
    end)
    
    HistEntry.MouseLeave:Connect(function()
        tween(HistEntry, {BackgroundColor3 = CurrentTheme.Secondary}, 0.2)
    end)
    
    return HistEntry
end

local function refreshHistory()
    for _, child in ipairs(HistScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for i, entry in ipairs(Data.History) do
        createHistoryEntry(entry, i)
    end
    
    HistScrollFrame.CanvasSize = UDim2.new(0, 0, 0, HistScrollLayout.AbsoluteContentSize.Y + 10)
end

ClearHistBtn.MouseButton1Click:Connect(function()
    if ClearHistBtn.Text == "⚠️ Confirm?" then
        Data.History = {}
        saveData()
        refreshHistory()
        notify("Cleared", "History has been cleared!", "Success")
        ClearHistBtn.Text = "🗑️ Clear All"
    else
        ClearHistBtn.Text = "⚠️ Confirm?"
        task.delay(3, function()
            if ClearHistBtn and ClearHistBtn.Parent then
                ClearHistBtn.Text = "🗑️ Clear All"
            end
        end)
    end
end)

ExportHistBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        local exportText = "=== Private Server HUB - History Export ===\n\n"
        for i, entry in ipairs(Data.History) do
            exportText = exportText..i..". "..entry.Name.." (PlaceId: "..entry.PlaceId..")\n"
        end
        setclipboard(exportText)
        notify("Exported", "History copied to clipboard!", "Success")
    end
end)

task.spawn(refreshHistory)

-- === QUEUE TAB CONTENT ===
local QueueHeader = Instance.new("TextLabel")
QueueHeader.Size = UDim2.new(1, -10, 0, 30)
QueueHeader.BackgroundTransparency = 1
QueueHeader.Text = "📋 Server Queue"
QueueHeader.TextColor3 = CurrentTheme.Text
QueueHeader.TextXAlignment = Enum.TextXAlignment.Left
QueueHeader.Font = Enum.Font.GothamBold
QueueHeader.TextSize = 16
QueueHeader.Parent = QueueTab

-- Queue Status
local QueueStatus = Instance.new("Frame")
QueueStatus.Size = UDim2.new(1, -10, 0, 70)
QueueStatus.BackgroundColor3 = CurrentTheme.Secondary
QueueStatus.BorderSizePixel = 0
QueueStatus.Parent = QueueTab

local QueueStatusCorner = Instance.new("UICorner")
QueueStatusCorner.CornerRadius = UDim.new(0, 10)
QueueStatusCorner.Parent = QueueStatus

local QueueIcon = Instance.new("TextLabel")
QueueIcon.Size = UDim2.new(0, 50, 0, 50)
QueueIcon.Position = UDim2.new(0, 10, 0.5, 0)
QueueIcon.AnchorPoint = Vector2.new(0, 0.5)
QueueIcon.BackgroundTransparency = 1
QueueIcon.Text = "⏳"
QueueIcon.TextSize = 32
QueueIcon.Parent = QueueStatus

local QueueStatusText = Instance.new("TextLabel")
QueueStatusText.Size = UDim2.new(1, -150, 0, 22)
QueueStatusText.Position = UDim2.new(0, 65, 0, 15)
QueueStatusText.BackgroundTransparency = 1
QueueStatusText.Text = "Queue Empty"
QueueStatusText.TextColor3 = CurrentTheme.Text
QueueStatusText.TextXAlignment = Enum.TextXAlignment.Left
QueueStatusText.Font = Enum.Font.GothamBold
QueueStatusText.TextSize = 14
QueueStatusText.Parent = QueueStatus

local QueueSubtext = Instance.new("TextLabel")
QueueSubtext.Size = UDim2.new(1, -150, 0, 18)
QueueSubtext.Position = UDim2.new(0, 65, 0, 38)
QueueSubtext.BackgroundTransparency = 1
QueueSubtext.Text = "Add servers to queue to join automatically"
QueueSubtext.TextColor3 = CurrentTheme.TextDim
QueueSubtext.TextXAlignment = Enum.TextXAlignment.Left
QueueSubtext.Font = Enum.Font.Gotham
QueueSubtext.TextSize = 11
QueueSubtext.Parent = QueueStatus

local StartQueueBtn = Instance.new("TextButton")
StartQueueBtn.Size = UDim2.new(0, 70, 0, 40)
StartQueueBtn.Position = UDim2.new(1, -80, 0.5, 0)
StartQueueBtn.AnchorPoint = Vector2.new(0, 0.5)
StartQueueBtn.BackgroundColor3 = CurrentTheme.Success
StartQueueBtn.Text = "▶️"
StartQueueBtn.TextSize = 20
StartQueueBtn.Parent = QueueStatus

local StartQueueCorner = Instance.new("UICorner")
StartQueueCorner.CornerRadius = UDim.new(0, 8)
StartQueueCorner.Parent = StartQueueBtn

-- Queue Settings
local QueueSettingsFrame = Instance.new("Frame")
QueueSettingsFrame.Size = UDim2.new(1, -10, 0, 45)
QueueSettingsFrame.BackgroundColor3 = CurrentTheme.Secondary
QueueSettingsFrame.BorderSizePixel = 0
QueueSettingsFrame.Parent = QueueTab

local QueueSettingsCorner = Instance.new("UICorner")
QueueSettingsCorner.CornerRadius = UDim.new(0, 8)
QueueSettingsCorner.Parent = QueueSettingsFrame

local QueueDelayLabel = Instance.new("TextLabel")
QueueDelayLabel.Size = UDim2.new(0.6, 0, 1, 0)
QueueDelayLabel.Position = UDim2.new(0, 15, 0, 0)
QueueDelayLabel.BackgroundTransparency = 1
QueueDelayLabel.Text = "⏱️ Delay between joins (seconds)"
QueueDelayLabel.TextColor3 = CurrentTheme.Text
QueueDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
QueueDelayLabel.Font = Enum.Font.GothamSemibold
QueueDelayLabel.TextSize = 12
QueueDelayLabel.Parent = QueueSettingsFrame

local QueueDelayInput = Instance.new("TextBox")
QueueDelayInput.Size = UDim2.new(0, 60, 0, 30)
QueueDelayInput.Position = UDim2.new(1, -75, 0.5, 0)
QueueDelayInput.AnchorPoint = Vector2.new(0, 0.5)
QueueDelayInput.BackgroundColor3 = CurrentTheme.Tertiary
QueueDelayInput.Text = tostring(Data.Settings.QueueDelay or 5)
QueueDelayInput.TextColor3 = CurrentTheme.Text
QueueDelayInput.Font = Enum.Font.GothamBold
QueueDelayInput.TextSize = 14
QueueDelayInput.Parent = QueueSettingsFrame

local QueueDelayCorner = Instance.new("UICorner")
QueueDelayCorner.CornerRadius = UDim.new(0, 6)
QueueDelayCorner.Parent = QueueDelayInput

QueueDelayInput:GetPropertyChangedSignal("Text"):Connect(function()
    local num = tonumber(QueueDelayInput.Text)
    if num and num >= 1 then
        Data.Settings.QueueDelay = num
        saveData()
    end
end)

-- Queue List
local QueueScrollFrame = Instance.new("ScrollingFrame")
QueueScrollFrame.Size = UDim2.new(1, -10, 0, 180)
QueueScrollFrame.BackgroundTransparency = 1
QueueScrollFrame.ScrollBarThickness = 4
QueueScrollFrame.ScrollBarImageColor3 = CurrentTheme.Accent
QueueScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
QueueScrollFrame.Parent = QueueTab

local QueueScrollLayout = Instance.new("UIListLayout")
QueueScrollLayout.Padding = UDim.new(0, 6)
QueueScrollLayout.Parent = QueueScrollFrame

local ServerQueue = {}
local QueueRunning = false

local function updateQueueStatus()
    if #ServerQueue == 0 then
        QueueStatusText.Text = "Queue Empty"
        QueueSubtext.Text = "Add servers to queue to join automatically"
        QueueIcon.Text = "⏳"
        StartQueueBtn.BackgroundColor3 = CurrentTheme.Tertiary
    elseif QueueRunning then
        QueueStatusText.Text = "Queue Running..."
        QueueSubtext.Text = #ServerQueue.." server(s) remaining"
        QueueIcon.Text = "🔄"
        StartQueueBtn.Text = "⏸️"
        StartQueueBtn.BackgroundColor3 = CurrentTheme.Warning
    else
        QueueStatusText.Text = #ServerQueue.." Server(s) in Queue"
        QueueSubtext.Text = "Press play to start joining"
        QueueIcon.Text = "📋"
        StartQueueBtn.Text = "▶️"
        StartQueueBtn.BackgroundColor3 = CurrentTheme.Success
    end
end

local function addToQueue(placeId, name, code)
    table.insert(ServerQueue, {
        PlaceId = placeId,
        Name = name,
        Code = code or generateCode(placeId),
        Added = os.time()
    })
    
    -- Create queue entry UI
    local QueueEntry = Instance.new("Frame")
    QueueEntry.Name = "QueueEntry_"..#ServerQueue
    QueueEntry.Size = UDim2.new(1, 0, 0, 45)
    QueueEntry.BackgroundColor3 = CurrentTheme.Secondary
    QueueEntry.BorderSizePixel = 0
    QueueEntry.Parent = QueueScrollFrame
    
    local EntryCorner = Instance.new("UICorner")
    EntryCorner.CornerRadius = UDim.new(0, 8)
    EntryCorner.Parent = QueueEntry
    
    local EntryPos = Instance.new("TextLabel")
    EntryPos.Size = UDim2.new(0, 25, 0, 25)
    EntryPos.Position = UDim2.new(0, 8, 0.5, 0)
    EntryPos.AnchorPoint = Vector2.new(0, 0.5)
    EntryPos.BackgroundColor3 = CurrentTheme.Accent
    EntryPos.Text = tostring(#ServerQueue)
    EntryPos.TextColor3 = Color3.new(1, 1, 1)
    EntryPos.Font = Enum.Font.GothamBold
    EntryPos.TextSize = 11
    EntryPos.Parent = QueueEntry
    
    local PosCorner = Instance.new("UICorner")
    PosCorner.CornerRadius = UDim.new(0, 6)
    PosCorner.Parent = EntryPos
    
    local EntryName = Instance.new("TextLabel")
    EntryName.Size = UDim2.new(1, -100, 1, 0)
    EntryName.Position = UDim2.new(0, 42, 0, 0)
    EntryName.BackgroundTransparency = 1
    EntryName.Text = name
    EntryName.TextColor3 = CurrentTheme.Text
    EntryName.TextXAlignment = Enum.TextXAlignment.Left
    EntryName.Font = Enum.Font.GothamSemibold
    EntryName.TextSize = 12
    EntryName.TextTruncate = Enum.TextTruncate.AtEnd
    EntryName.Parent = QueueEntry
    
    local RemoveBtn = Instance.new("TextButton")
    RemoveBtn.Size = UDim2.new(0, 35, 0, 30)
    RemoveBtn.Position = UDim2.new(1, -45, 0.5, 0)
    RemoveBtn.AnchorPoint = Vector2.new(0, 0.5)
    RemoveBtn.BackgroundColor3 = CurrentTheme.Error
    RemoveBtn.Text = "✕"
    RemoveBtn.TextColor3 = Color3.new(1, 1, 1)
    RemoveBtn.Font = Enum.Font.GothamBold
    RemoveBtn.TextSize = 14
    RemoveBtn.Parent = QueueEntry
    
    local RemoveCorner = Instance.new("UICorner")
    RemoveCorner.CornerRadius = UDim.new(0, 6)
    RemoveCorner.Parent = RemoveBtn
    
    RemoveBtn.MouseButton1Click:Connect(function()
        for i, q in ipairs(ServerQueue) do
            if q.PlaceId == placeId then
                table.remove(ServerQueue, i)
                break
            end
        end
        tween(QueueEntry, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
        task.wait(0.2)
        QueueEntry:Destroy()
        QueueScrollFrame.CanvasSize = UDim2.new(0, 0, 0, QueueScrollLayout.AbsoluteContentSize.Y + 10)
        updateQueueStatus()
    end)
    
    QueueScrollFrame.CanvasSize = UDim2.new(0, 0, 0, QueueScrollLayout.AbsoluteContentSize.Y + 10)
    updateQueueStatus()
    notify("Added to Queue", name.." added to server queue", "Success")
end

local function processQueue()
    if #ServerQueue == 0 then
        QueueRunning = false
        updateQueueStatus()
        notify("Queue Complete", "All servers have been processed!", "Success")
        return
    end
    
    QueueRunning = true
    updateQueueStatus()
    
    local current = ServerQueue[1]
    notify("Queue", "Joining "..current.Name.."...", "Info")
    
    pcall(function()
        RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(current.PlaceId, "", current.Code)
    end)
    
    table.remove(ServerQueue, 1)
    
    -- Remove UI entry
    local firstEntry = QueueScrollFrame:FindFirstChild("QueueEntry_1")
    if firstEntry then
        firstEntry:Destroy()
    end
    
    -- Rename remaining entries
    for i, child in ipairs(QueueScrollFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("QueueEntry_") then
            child.Name = "QueueEntry_"..i
            local posLabel = child:FindFirstChild("TextLabel")
            if posLabel then
                posLabel.Text = tostring(i)
            end
        end
    end
    
    QueueScrollFrame.CanvasSize = UDim2.new(0, 0, 0, QueueScrollLayout.AbsoluteContentSize.Y + 10)
end

StartQueueBtn.MouseButton1Click:Connect(function()
    if QueueRunning then
        QueueRunning = false
        updateQueueStatus()
        notify("Queue Paused", "Queue has been paused", "Warning")
    else
        if #ServerQueue > 0 then
            processQueue()
        else
            notify("Queue Empty", "Add servers to the queue first!", "Warning")
        end
    end
end)

-- === STATS TAB CONTENT ===
local StatsHeader = Instance.new("TextLabel")
StatsHeader.Size = UDim2.new(1, -10, 0, 30)
StatsHeader.BackgroundTransparency = 1
StatsHeader.Text = "📊 Statistics"
StatsHeader.TextColor3 = CurrentTheme.Text
StatsHeader.TextXAlignment = Enum.TextXAlignment.Left
StatsHeader.Font = Enum.Font.GothamBold
StatsHeader.TextSize = 16
StatsHeader.Parent = StatsTab

-- Stats Grid
local StatsGrid = Instance.new("Frame")
StatsGrid.Size = UDim2.new(1, -10, 0, 180)
StatsGrid.BackgroundTransparency = 1
StatsGrid.Parent = StatsTab

local StatsGridLayout = Instance.new("UIGridLayout")
StatsGridLayout.CellSize = UDim2.new(0.48, 0, 0, 80)
StatsGridLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
StatsGridLayout.Parent = StatsGrid

local function createStatCard(icon, value, label, color)
    local Card = Instance.new("Frame")
    Card.BackgroundColor3 = CurrentTheme.Secondary
    Card.BorderSizePixel = 0
    Card.Parent = StatsGrid
    
    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 10)
    CardCorner.Parent = Card
    
    local CardAccent = Instance.new("Frame")
    CardAccent.Size = UDim2.new(0, 4, 0.6, 0)
    CardAccent.Position = UDim2.new(0, 0, 0.2, 0)
    CardAccent.BackgroundColor3 = color or CurrentTheme.Accent
    CardAccent.BorderSizePixel = 0
    CardAccent.Parent = Card
    
    local AccentCorner = Instance.new("UICorner")
    AccentCorner.CornerRadius = UDim.new(0, 2)
    AccentCorner.Parent = CardAccent
    
    local CardIcon = Instance.new("TextLabel")
    CardIcon.Size = UDim2.new(0, 35, 0, 35)
    CardIcon.Position = UDim2.new(0, 15, 0, 12)
    CardIcon.BackgroundTransparency = 1
    CardIcon.Text = icon
    CardIcon.TextSize = 24
    CardIcon.Parent = Card
    
    local CardValue = Instance.new("TextLabel")
    CardValue.Size = UDim2.new(1, -60, 0, 25)
    CardValue.Position = UDim2.new(0, 55, 0, 12)
    CardValue.BackgroundTransparency = 1
    CardValue.Text = tostring(value)
    CardValue.TextColor3 = CurrentTheme.Text
    CardValue.TextXAlignment = Enum.TextXAlignment.Left
    CardValue.Font = Enum.Font.GothamBold
    CardValue.TextSize = 20
    CardValue.Parent = Card
    
    local CardLabel = Instance.new("TextLabel")
    CardLabel.Size = UDim2.new(1, -20, 0, 18)
    CardLabel.Position = UDim2.new(0, 15, 0, 50)
    CardLabel.BackgroundTransparency = 1
    CardLabel.Text = label
    CardLabel.TextColor3 = CurrentTheme.TextDim
    CardLabel.TextXAlignment = Enum.TextXAlignment.Left
    CardLabel.Font = Enum.Font.Gotham
    CardLabel.TextSize = 11
    CardLabel.Parent = Card
    
    return Card
end

-- Calculate stats
local function calculateStats()
    local totalJoins = #Data.History
    local totalFavorites = 0
    for _ in pairs(Data.Favorites) do
        totalFavorites = totalFavorites + 1
    end
    local totalCategories = #Data.Categories
    local uniqueGames = {}
    for _, entry in ipairs(Data.History) do
        uniqueGames[entry.PlaceId] = true
    end
    local uniqueCount = 0
    for _ in pairs(uniqueGames) do
        uniqueCount = uniqueCount + 1
    end
    
    return totalJoins, totalFavorites, totalCategories, uniqueCount
end

local joins, favs, cats, unique = calculateStats()

createStatCard("🚀", joins, "Total Joins", CurrentTheme.Accent)
createStatCard("⭐", favs, "Saved Favorites", CurrentTheme.Warning)
createStatCard("📁", cats, "Categories", CurrentTheme.Success)
createStatCard("🎮", unique, "Unique Games", CurrentTheme.Error)

-- Activity Chart (Simple)
local ActivityHeader = Instance.new("TextLabel")
ActivityHeader.Size = UDim2.new(1, -10, 0, 25)
ActivityHeader.BackgroundTransparency = 1
ActivityHeader.Text = "📈 Recent Activity"
ActivityHeader.TextColor3 = CurrentTheme.Text
ActivityHeader.TextXAlignment = Enum.TextXAlignment.Left
ActivityHeader.Font = Enum.Font.GothamSemibold
ActivityHeader.TextSize = 13
ActivityHeader.Parent = StatsTab

local ActivityChart = Instance.new("Frame")
ActivityChart.Size = UDim2.new(1, -10, 0, 80)
ActivityChart.BackgroundColor3 = CurrentTheme.Secondary
ActivityChart.BorderSizePixel = 0
ActivityChart.Parent = StatsTab

local ChartCorner = Instance.new("UICorner")
ChartCorner.CornerRadius = UDim.new(0, 10)
ChartCorner.Parent = ActivityChart

local ChartLayout = Instance.new("UIListLayout")
ChartLayout.FillDirection = Enum.FillDirection.Horizontal
ChartLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ChartLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
ChartLayout.Padding = UDim.new(0, 4)
ChartLayout.Parent = ActivityChart

local ChartPadding = Instance.new("UIPadding")
ChartPadding.PaddingBottom = UDim.new(0, 10)
ChartPadding.Parent = ActivityChart

-- Generate activity bars for last 7 days
local dayActivity = {}
for i = 1, 7 do
    dayActivity[i] = 0
end

for _, entry in ipairs(Data.History) do
    local daysAgo = math.floor((os.time() - entry.Time) / 86400)
    if daysAgo >= 0 and daysAgo < 7 then
        dayActivity[7 - daysAgo] = dayActivity[7 - daysAgo] + 1
    end
end

local maxActivity = math.max(unpack(dayActivity), 1)

for i, count in ipairs(dayActivity) do
    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(0, 28, count / maxActivity * 0.7, 0)
    Bar.BackgroundColor3 = CurrentTheme.Accent
    Bar.BorderSizePixel = 0
    Bar.Parent = ActivityChart
    
    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(0, 4)
    BarCorner.Parent = Bar
    
    local DayLabel = Instance.new("TextLabel")
    DayLabel.Size = UDim2.new(1, 0, 0, 12)
    DayLabel.Position = UDim2.new(0, 0, 1, 2)
    DayLabel.BackgroundTransparency = 1
    DayLabel.Text = ({"S","M","T","W","T","F","S"})[((os.date("*t").wday - 1 + i - 7) % 7) + 1]
    DayLabel.TextColor3 = CurrentTheme.TextDim
    DayLabel.Font = Enum.Font.Gotham
    DayLabel.TextSize = 9
    DayLabel.Parent = Bar
end

-- === SETTINGS TAB CONTENT ===
local SettingsHeader = Instance.new("TextLabel")
SettingsHeader.Size = UDim2.new(1, -10, 0, 30)
SettingsHeader.BackgroundTransparency = 1
SettingsHeader.Text = "⚙️ Settings"
SettingsHeader.TextColor3 = CurrentTheme.Text
SettingsHeader.TextXAlignment = Enum.TextXAlignment.Left
SettingsHeader.Font = Enum.Font.GothamBold
SettingsHeader.TextSize = 16
SettingsHeader.Parent = SettingsTab

-- Settings Sections
local function createSettingsSection(title)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, -10, 0, 25)
    Section.BackgroundTransparency = 1
    Section.Parent = SettingsTab
    
    local SectionLabel = Instance.new("TextLabel")
    SectionLabel.Size = UDim2.new(1, 0, 1, 0)
    SectionLabel.BackgroundTransparency = 1
    SectionLabel.Text = title
    SectionLabel.TextColor3 = CurrentTheme.Accent
    SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    SectionLabel.Font = Enum.Font.GothamBold
    SectionLabel.TextSize = 12
    SectionLabel.Parent = Section
    
    return Section
end

createSettingsSection("🔧 General")

createToggle(SettingsTab, "🔄 Auto Rejoin on Disconnect", Data.Settings.AutoRejoin, function(state)
    Data.Settings.AutoRejoin = state
    Config.AutoRejoin = state
    saveData()
    notify("Setting Changed", "Auto Rejoin "..(state and "enabled" or "disabled"), "Info")
end)

createToggle(SettingsTab, "⏸️ Anti-AFK", Data.Settings.AntiAFK, function(state)
    Data.Settings.AntiAFK = state
    Config.AntiAFK = state
    saveData()
    notify("Setting Changed", "Anti-AFK "..(state and "enabled" or "disabled"), "Info")
end)

createToggle(SettingsTab, "🔔 Notifications", Data.Settings.Notifications, function(state)
    Data.Settings.Notifications = state
    saveData()
end)

createToggle(SettingsTab, "📋 Use Queue System", Data.Settings.UseQueue or false, function(state)
    Data.Settings.UseQueue = state
    saveData()
    notify("Setting Changed", "Queue System "..(state and "enabled" or "disabled"), "Info")
end)

createSettingsSection("🎨 Appearance")

-- Theme Selector
local ThemeContainer = Instance.new("Frame")
ThemeContainer.Size = UDim2.new(1, -10, 0, 45)
ThemeContainer.BackgroundColor3 = CurrentTheme.Secondary
ThemeContainer.BorderSizePixel = 0
ThemeContainer.Parent = SettingsTab

local ThemeContainerCorner = Instance.new("UICorner")
ThemeContainerCorner.CornerRadius = UDim.new(0, 8)
ThemeContainerCorner.Parent = ThemeContainer

local ThemeLabel = Instance.new("TextLabel")
ThemeLabel.Size = UDim2.new(0.4, 0, 1, 0)
ThemeLabel.Position = UDim2.new(0, 15, 0, 0)
ThemeLabel.BackgroundTransparency = 1
ThemeLabel.Text = "🎨 Theme"
ThemeLabel.TextColor3 = CurrentTheme.Text
ThemeLabel.TextXAlignment = Enum.TextXAlignment.Left
ThemeLabel.Font = Enum.Font.GothamSemibold
ThemeLabel.TextSize = 13
ThemeLabel.Parent = ThemeContainer

local ThemeButtons = Instance.new("Frame")
ThemeButtons.Size = UDim2.new(0.55, 0, 0, 30)
ThemeButtons.Position = UDim2.new(0.42, 0, 0.5, 0)
ThemeButtons.AnchorPoint = Vector2.new(0, 0.5)
ThemeButtons.BackgroundTransparency = 1
ThemeButtons.Parent = ThemeContainer

local ThemeBtnLayout = Instance.new("UIListLayout")
ThemeBtnLayout.FillDirection = Enum.FillDirection.Horizontal
ThemeBtnLayout.Padding = UDim.new(0, 5)
ThemeBtnLayout.Parent = ThemeButtons

local themeOrder = {"Dark", "Light", "Midnight", "Ocean", "Neon"}
for _, themeName in ipairs(themeOrder) do
    if Themes[themeName] then
        local ThemeBtn = Instance.new("TextButton")
        ThemeBtn.Size = UDim2.new(0, 55, 1, 0)
        ThemeBtn.BackgroundColor3 = Themes[themeName].Accent
        ThemeBtn.Text = themeName:sub(1, 1)
        ThemeBtn.TextColor3 = Color3.new(1, 1, 1)
        ThemeBtn.Font = Enum.Font.GothamBold
        ThemeBtn.TextSize = 12
        ThemeBtn.Parent = ThemeButtons
        
        local ThemeBtnCorner = Instance.new("UICorner")
        ThemeBtnCorner.CornerRadius = UDim.new(0, 6)
        ThemeBtnCorner.Parent = ThemeBtn
        
        if themeName == Config.Theme then
            local ThemeBorder = Instance.new("UIStroke")
            ThemeBorder.Color = Color3.new(1, 1, 1)
            ThemeBorder.Thickness = 2
            ThemeBorder.Parent = ThemeBtn
        end
        
        ThemeBtn.MouseButton1Click:Connect(function()
            Data.Settings.Theme = themeName
            saveData()
            notify("Theme Changed", "Restart script to apply "..themeName.." theme", "Info", 5)
        end)
    end
end

createSettingsSection("📦 Data Management")

-- Export/Import Buttons
local DataButtonRow = Instance.new("Frame")
DataButtonRow.Size = UDim2.new(1, -10, 0, 40)
DataButtonRow.BackgroundTransparency = 1
DataButtonRow.Parent = SettingsTab

local DataBtnLayout = Instance.new("UIListLayout")
DataBtnLayout.FillDirection = Enum.FillDirection.Horizontal
DataBtnLayout.Padding = UDim.new(0, 8)
DataBtnLayout.Parent = DataButtonRow

local ExportBtn = createButton(DataButtonRow, "📤 Export All", CurrentTheme.Accent, UDim2.new(0.48, 0, 1, 0))
local ImportBtn = createButton(DataButtonRow, "📥 Import", CurrentTheme.Tertiary, UDim2.new(0.48, 0, 1, 0))

ExportBtn.MouseButton1Click:Connect(function()
    local exportData = HttpService:JSONEncode({
        Favorites = Data.Favorites,
        Categories = Data.Categories,
        Settings = Data.Settings,
        ExportDate = os.time(),
        Version = Config.Version
    })
    if setclipboard then
        setclipboard(exportData)
        notify("Exported", "All data copied to clipboard!", "Success")
    end
end)

ImportBtn.MouseButton1Click:Connect(function()
    notify("Import", "Paste exported data in the Join tab's PlaceId field, then use 📥 Import again", "Info", 5)
end)

-- Reset Button
local ResetBtn = createButton(SettingsTab, "🔄 Reset All Data", CurrentTheme.Error, UDim2.new(1, -10, 0, 40))

ResetBtn.MouseButton1Click:Connect(function()
    if ResetBtn.Text == "⚠️ Click again to confirm reset!" then
        Data.Favorites = {}
        Data.History = {}
        Data.Categories = {
            {Name = "Default", Icon = "📁", Color = CurrentTheme.Accent},
            {Name = "Simulators", Icon = "🎮", Color = CurrentTheme.Success},
            {Name = "FPS", Icon = "🎯", Color = CurrentTheme.Error},
            {Name = "RPG", Icon = "⚔️", Color = CurrentTheme.Warning}
        }
        saveData()
        notify("Reset Complete", "All data has been reset!", "Warning")
        ResetBtn.Text = "🔄 Reset All Data"
    else
        ResetBtn.Text = "⚠️ Click again to confirm reset!"
        task.delay(3, function()
            if ResetBtn and ResetBtn.Parent then
                ResetBtn.Text = "🔄 Reset All Data"
            end
        end)
    end
end)

-- Credits Section
local CreditsFrame = Instance.new("Frame")
CreditsFrame.Size = UDim2.new(1, -10, 0, 70)
CreditsFrame.BackgroundColor3 = CurrentTheme.Secondary
CreditsFrame.BorderSizePixel = 0
CreditsFrame.Parent = SettingsTab

local CreditsCorner = Instance.new("UICorner")
CreditsCorner.CornerRadius = UDim.new(0, 10)
CreditsCorner.Parent = CreditsFrame

local CreditsIcon = Instance.new("TextLabel")
CreditsIcon.Size = UDim2.new(0, 50, 0, 50)
CreditsIcon.Position = UDim2.new(0, 10, 0.5, 0)
CreditsIcon.AnchorPoint = Vector2.new(0, 0.5)
CreditsIcon.BackgroundTransparency = 1
CreditsIcon.Text = "⚡"
CreditsIcon.TextSize = 32
CreditsIcon.Parent = CreditsFrame

local CreditsText = Instance.new("TextLabel")
CreditsText.Size = UDim2.new(1, -80, 0, 20)
CreditsText.Position = UDim2.new(0, 65, 0, 15)
CreditsText.BackgroundTransparency = 1
CreditsText.Text = "Private Server HUB v"..Config.Version
CreditsText.TextColor3 = CurrentTheme.Text
CreditsText.TextXAlignment = Enum.TextXAlignment.Left
CreditsText.Font = Enum.Font.GothamBold
CreditsText.TextSize = 14
CreditsText.Parent = CreditsFrame

local CreditsSubtext = Instance.new("TextLabel")
CreditsSubtext.Size = UDim2.new(1, -80, 0, 16)
CreditsSubtext.Position = UDim2.new(0, 65, 0, 38)
CreditsSubtext.BackgroundTransparency = 1
CreditsSubtext.Text = "Made with ❤️ by ADMC • Press "..Config.ToggleKey.Name.." to toggle"
CreditsSubtext.TextColor3 = CurrentTheme.TextDim
CreditsSubtext.TextXAlignment = Enum.TextXAlignment.Left
CreditsSubtext.Font = Enum.Font.Gotham
CreditsSubtext.TextSize = 11
CreditsSubtext.Parent = CreditsFrame

-- Update all scroll frames canvas sizes
local function updateAllCanvasSizes()
    for _, tab in pairs(Tabs) do
        if tab.Content:IsA("ScrollingFrame") then
            local layout = tab.Content:FindFirstChildOfClass("UIListLayout")
            if layout then
                tab.Content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 30)
            end
        end
    end
end

task.spawn(updateAllCanvasSizes)

-- === EDIT MODAL ===
local EditModal = Instance.new("Frame")
EditModal.Name = "EditModal"
EditModal.Size = UDim2.new(0, 350, 0, 280)
EditModal.Position = UDim2.new(0.5, 0, 0.5, 0)
EditModal.AnchorPoint = Vector2.new(0.5, 0.5)
EditModal.BackgroundColor3 = CurrentTheme.Primary
EditModal.BorderSizePixel = 0
EditModal.Visible = false
EditModal.ZIndex = 100
EditModal.Parent = ScreenGui

local EditModalCorner = Instance.new("UICorner")
EditModalCorner.CornerRadius = UDim.new(0, 12)
EditModalCorner.Parent = EditModal

local EditModalStroke = Instance.new("UIStroke")
EditModalStroke.Color = CurrentTheme.Border
EditModalStroke.Thickness = 2
EditModalStroke.Parent = EditModal

local EditModalTitle = Instance.new("TextLabel")
EditModalTitle.Size = UDim2.new(1, -50, 0, 40)
EditModalTitle.Position = UDim2.new(0, 15, 0, 0)
EditModalTitle.BackgroundTransparency = 1
EditModalTitle.Text = "✏️ Edit Favorite"
EditModalTitle.TextColor3 = CurrentTheme.Text
EditModalTitle.TextXAlignment = Enum.TextXAlignment.Left
EditModalTitle.Font = Enum.Font.GothamBold
EditModalTitle.TextSize = 16
EditModalTitle.ZIndex = 101
EditModalTitle.Parent = EditModal

local CloseModalBtn = Instance.new("TextButton")
CloseModalBtn.Size = UDim2.new(0, 30, 0, 30)
CloseModalBtn.Position = UDim2.new(1, -40, 0, 5)
CloseModalBtn.BackgroundColor3 = CurrentTheme.Error
CloseModalBtn.Text = "✕"
CloseModalBtn.TextColor3 = Color3.new(1, 1, 1)
CloseModalBtn.Font = Enum.Font.GothamBold
CloseModalBtn.TextSize = 14
CloseModalBtn.ZIndex = 101
CloseModalBtn.Parent = EditModal

local CloseModalCorner = Instance.new("UICorner")
CloseModalCorner.CornerRadius = UDim.new(0, 6)
CloseModalCorner.Parent = CloseModalBtn

local EditContent = Instance.new("Frame")
EditContent.Size = UDim2.new(1, -30, 1, -50)
EditContent.Position = UDim2.new(0, 15, 0, 45)
EditContent.BackgroundTransparency = 1
EditContent.ZIndex = 101
EditContent.Parent = EditModal

local EditLayout = Instance.new("UIListLayout")
EditLayout.Padding = UDim.new(0, 12)
EditLayout.Parent = EditContent

-- Edit Name Input
local EditNameLabel = Instance.new("TextLabel")
EditNameLabel.Size = UDim2.new(1, 0, 0, 20)
EditNameLabel.BackgroundTransparency = 1
EditNameLabel.Text = "Game Name"
EditNameLabel.TextColor3 = CurrentTheme.TextDim
EditNameLabel.TextXAlignment = Enum.TextXAlignment.Left
EditNameLabel.Font = Enum.Font.GothamSemibold
EditNameLabel.TextSize = 12
EditNameLabel.ZIndex = 101
EditNameLabel.Parent = EditContent

local EditNameInput = Instance.new("TextBox")
EditNameInput.Size = UDim2.new(1, 0, 0, 38)
EditNameInput.BackgroundColor3 = CurrentTheme.Secondary
EditNameInput.Text = ""
EditNameInput.PlaceholderText = "Enter game name..."
EditNameInput.PlaceholderColor3 = CurrentTheme.TextDim
EditNameInput.TextColor3 = CurrentTheme.Text
EditNameInput.Font = Enum.Font.Gotham
EditNameInput.TextSize = 14
EditNameInput.TextXAlignment = Enum.TextXAlignment.Left
EditNameInput.ClearTextOnFocus = false
EditNameInput.ZIndex = 101
EditNameInput.Parent = EditContent

local EditNameCorner = Instance.new("UICorner")
EditNameCorner.CornerRadius = UDim.new(0, 8)
EditNameCorner.Parent = EditNameInput

local EditNamePadding = Instance.new("UIPadding")
EditNamePadding.PaddingLeft = UDim.new(0, 10)
EditNamePadding.Parent = EditNameInput

-- Edit Category
local EditCatLabel = Instance.new("TextLabel")
EditCatLabel.Size = UDim2.new(1, 0, 0, 20)
EditCatLabel.BackgroundTransparency = 1
EditCatLabel.Text = "Category"
EditCatLabel.TextColor3 = CurrentTheme.TextDim
EditCatLabel.TextXAlignment = Enum.TextXAlignment.Left
EditCatLabel.Font = Enum.Font.GothamSemibold
EditCatLabel.TextSize = 12
EditCatLabel.ZIndex = 101
EditCatLabel.Parent = EditContent

local EditCatContainer = Instance.new("Frame")
EditCatContainer.Size = UDim2.new(1, 0, 0, 35)
EditCatContainer.BackgroundTransparency = 1
EditCatContainer.ZIndex = 101
EditCatContainer.Parent = EditContent

local EditCatLayout = Instance.new("UIListLayout")
EditCatLayout.FillDirection = Enum.FillDirection.Horizontal
EditCatLayout.Padding = UDim.new(0, 6)
EditCatLayout.Parent = EditCatContainer

local CurrentEditId = nil
local CurrentEditData = nil
local SelectedEditCategory = "Default"

local function populateEditCategories()
    for _, child in ipairs(EditCatContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for _, cat in ipairs(Data.Categories) do
        local CatBtn = Instance.new("TextButton")
        CatBtn.Size = UDim2.new(0, 70, 1, 0)
        CatBtn.BackgroundColor3 = SelectedEditCategory == cat.Name and CurrentTheme.Accent or CurrentTheme.Tertiary
        CatBtn.Text = cat.Icon.." "..cat.Name:sub(1, 6)
        CatBtn.TextColor3 = Color3.new(1, 1, 1)
        CatBtn.Font = Enum.Font.GothamSemibold
        CatBtn.TextSize = 10
        CatBtn.ZIndex = 101
        CatBtn.Parent = EditCatContainer
        
        local CatBtnCorner = Instance.new("UICorner")
        CatBtnCorner.CornerRadius = UDim.new(0, 6)
        CatBtnCorner.Parent = CatBtn
        
        CatBtn.MouseButton1Click:Connect(function()
            SelectedEditCategory = cat.Name
            populateEditCategories()
        end)
    end
end

-- Save Edit Button
local SaveEditBtn = Instance.new("TextButton")
SaveEditBtn.Size = UDim2.new(1, 0, 0, 42)
SaveEditBtn.BackgroundColor3 = CurrentTheme.Success
SaveEditBtn.Text = "💾 Save Changes"
SaveEditBtn.TextColor3 = Color3.new(1, 1, 1)
SaveEditBtn.Font = Enum.Font.GothamBold
SaveEditBtn.TextSize = 14
SaveEditBtn.ZIndex = 101
SaveEditBtn.Parent = EditContent

local SaveEditCorner = Instance.new("UICorner")
SaveEditCorner.CornerRadius = UDim.new(0, 8)
SaveEditCorner.Parent = SaveEditBtn

function openEditModal(id, data)
    CurrentEditId = id
    CurrentEditData = data
    EditNameInput.Text = data.Name or ""
    SelectedEditCategory = data.Category or "Default"
    populateEditCategories()
    
    EditModal.Visible = true
    EditModal.Size = UDim2.new(0, 0, 0, 0)
    tween(EditModal, {Size = UDim2.new(0, 350, 0, 280)}, 0.3, Enum.EasingStyle.Back)
end

CloseModalBtn.MouseButton1Click:Connect(function()
    tween(EditModal, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
    task.wait(0.2)
    EditModal.Visible = false
end)

SaveEditBtn.MouseButton1Click:Connect(function()
    if CurrentEditId and CurrentEditData then
        CurrentEditData.Name = EditNameInput.Text
        CurrentEditData.Category = SelectedEditCategory
        Data.Favorites[CurrentEditId] = CurrentEditData
        saveData()
        
        notify("Saved", "Changes saved successfully!", "Success")
        refreshFavorites()
        
        tween(EditModal, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
        task.wait(0.2)
        EditModal.Visible = false
    end
end)

-- === DRAGGING FUNCTIONALITY ===
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

-- === WINDOW CONTROLS ===
local minimized = false
local originalSize = UDim2.new(0, 550, 0, 500)

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        tween(MainFrame, {Size = UDim2.new(0, 550, 0, 50)}, 0.3, Enum.EasingStyle.Quart)
        MinimizeBtn.Text = "+"
        ContentHolder.Visible = false
        TabHolder.Visible = false
    else
        tween(MainFrame, {Size = originalSize}, 0.3, Enum.EasingStyle.Quart)
        MinimizeBtn.Text = "─"
        task.wait(0.2)
        ContentHolder.Visible = true
        TabHolder.Visible = true
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    notify("Goodbye!", "Thanks for using Private Server HUB!", "Info", 2)
    task.wait(0.5)
    tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.wait(0.35)
    ScreenGui:Destroy()
end)

-- === KEYBIND TOGGLE ===
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Config.ToggleKey then
        if ScreenGui.Enabled then
            tween(MainFrame, {Position = UDim2.new(0.5, -275, -0.5, 0)}, 0.3, Enum.EasingStyle.Quart)
            task.wait(0.3)
            ScreenGui.Enabled = false
        else
            ScreenGui.Enabled = true
            MainFrame.Position = UDim2.new(0.5, -275, 1.5, 0)
            tween(MainFrame, {Position = UDim2.new(0.5, -275, 0.5, -250)}, 0.3, Enum.EasingStyle.Quart)
        end
    end
end)

-- === ANTI-AFK ===
Players.LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        notify("Anti-AFK", "You were about to be kicked for being idle. Prevented!", "Warning", 3)
    end
end)

-- === AUTO-REJOIN ===
local promptGui = CoreGui:WaitForChild("RobloxPromptGui", 5)
if promptGui then
    local overlay = promptGui:WaitForChild("promptOverlay", 5)
    if overlay then
        overlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" and Config.AutoRejoin then
                notify("Disconnected", "Auto-rejoining in 3 seconds...", "Warning")
                task.wait(3)
                TeleportService:Teleport(game.PlaceId)
            end
        end)
    end
end

-- === OPENING ANIMATION ===
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundTransparency = 1

task.wait(0.1)

tween(MainFrame, {BackgroundTransparency = 0}, 0.2)
tween(MainFrame, {Size = originalSize, Position = UDim2.new(0.5, -275, 0.5, -250)}, 0.5, Enum.EasingStyle.Back)

-- Loading animation for content
task.wait(0.3)
for _, tab in pairs(Tabs) do
    tab.Content.GroupTransparency = 1
end
task.wait(0.2)
for _, tab in pairs(Tabs) do
    tween(tab.Content, {GroupTransparency = 0}, 0.3)
end

-- Welcome notification
task.wait(0.6)
notify("Welcome!", "Private Server HUB v"..Config.Version.." loaded!", "Success", 4)
notify("Tip", "Press "..Config.ToggleKey.Name.." to toggle the UI", "Info", 6)

-- === PERIODIC SAVES ===
task.spawn(function()
    while task.wait(60) do
        saveData()
    end
end)

-- === CONSOLE OUTPUT ===
print("══════════════════════════════════════════")
print("⚡ Private Server HUB v"..Config.Version.." loaded!")
print("══════════════════════════════════════════")
print("🎮 Press "..Config.ToggleKey.Name.." to toggle the UI")
print("📁 Data saved to: "..Config.SavePath)
print("⭐ Favorites: "..tostring(select(2, calculateStats())))
print("📜 History entries: "..tostring(#Data.History))
print("══════════════════════════════════════════")
