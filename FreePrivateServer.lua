-- ⚡ Private Server HUB by ADMC
-- ✅ Private Server Joiner + Favoris persistants + Delete + Anti-AFK + Auto-Rejoin

-- === Core Functions (MD5 + HMAC + Base64) ===
local t={0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,0x6b901122,0xfd987193,0xa679438e,0x49b40821,0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391}

local function h(m)
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

local function hm(k,m,hf)
    if #k>64 then k=hf(k) end
    local okp,ikp="",""
    for i=1,64 do
        local by=(i<=#k and string.byte(k,i))or 0
        okp=okp..string.char(bit32.bxor(by,0x5C))
        ikp=ikp..string.char(bit32.bxor(by,0x36))
    end
    return hf(okp..hf(ikp..m))
end

local function b64(dt)
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

local function gc(pid)
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
    local sig=hm("e4Yn8ckbCJtw2sv7qmbg",ct,h) -- secret key
    local acb=sig..ct
    local ac=b64(acb):gsub("+","-"):gsub("/","_")
    local pd=0
    ac=ac:gsub("=",function()pd=pd+1 return""end)
    ac=ac..tostring(pd)
    return ac
end

-- === GUI ===
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 350, 0, 280)
frame.Position = UDim2.new(0.35, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,35)
title.BackgroundColor3 = Color3.fromRGB(45,45,45)
title.Text = "⚡ Private Server HUB"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20

local placeBox = Instance.new("TextBox", frame)
placeBox.Size = UDim2.new(0.9,0,0,30)
placeBox.Position = UDim2.new(0.05,0,0.18,0)
placeBox.PlaceholderText = "PlaceId"
placeBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
placeBox.TextColor3 = Color3.new(1,1,1)

local joinBtn = Instance.new("TextButton", frame)
joinBtn.Size = UDim2.new(0.9,0,0,35)
joinBtn.Position = UDim2.new(0.05,0,0.3,0)
joinBtn.BackgroundColor3 = Color3.fromRGB(0,120,200)
joinBtn.Text = "🚀 Generate & Join"
joinBtn.TextColor3 = Color3.new(1,1,1)
joinBtn.Font = Enum.Font.SourceSansBold
joinBtn.TextSize = 20

local favBtn = Instance.new("TextButton", frame)
favBtn.Size = UDim2.new(0.9,0,0,30)
favBtn.Position = UDim2.new(0.05,0,0.45,0)
favBtn.BackgroundColor3 = Color3.fromRGB(0,200,100)
favBtn.Text = "⭐ Add to Favorites"
favBtn.TextColor3 = Color3.new(1,1,1)

local favList = Instance.new("ScrollingFrame", frame)
favList.Size = UDim2.new(0.9,0,0,80)
favList.Position = UDim2.new(0.05,0,0.61,0)
favList.CanvasSize = UDim2.new(0,0,0,0)
favList.BackgroundColor3 = Color3.fromRGB(40,40,40)

-- === FAVORIS avec SAUVEGARDE ===
local favs = {}
local savePath = "PrivateServer_Favorites.json"

if isfile and isfile(savePath) then
    local data = readfile(savePath)
    local ok, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(data) end)
    if ok and type(decoded)=="table" then favs = decoded end
end

local function saveFavs()
    if writefile then
        local data = game:GetService("HttpService"):JSONEncode(favs)
        writefile(savePath, data)
    end
end

function refreshFavs()
    favList:ClearAllChildren()
    local y=0
    for name,pid in pairs(favs) do
        local b = Instance.new("TextButton", favList)
        b.Size = UDim2.new(1,0,0,25)
        b.Position = UDim2.new(0,0,0,y)
        b.BackgroundColor3 = Color3.fromRGB(60,60,60)
        b.Text = name.." ("..pid..")"
        b.TextColor3 = Color3.new(1,1,1)

        -- Clic gauche -> rejoindre
        b.MouseButton1Click:Connect(function()
            local ac = gc(pid)
            setclipboard(ac.."\n"..tostring(pid))
            game:GetService("RobloxReplicatedStorage").ContactListIrisInviteTeleport:FireServer(pid,"",ac)
        end)
        -- Clic droit -> supprimer
        b.MouseButton2Click:Connect(function()
            favs[name]=nil
            saveFavs()
            refreshFavs()
        end)

        y=y+30
    end
    favList.CanvasSize = UDim2.new(0,0,0,y)
end

joinBtn.MouseButton1Click:Connect(function()
    local placeId = tonumber(placeBox.Text)
    if placeId then
        local ac = gc(placeId)
        setclipboard(ac .. "\n" .. tostring(placeId))
        game:GetService("RobloxReplicatedStorage").ContactListIrisInviteTeleport:FireServer(placeId,"",ac)
        joinBtn.Text = "✅ Teleporting..."
        wait(2)
        joinBtn.Text = "🚀 Generate & Join"
    else
        joinBtn.Text = "❌ Invalid"
        wait(1.5)
        joinBtn.Text = "🚀 Generate & Join"
    end
end)

favBtn.MouseButton1Click:Connect(function()
    local placeId = tonumber(placeBox.Text)
    if placeId then
        favs["Game_"..placeId] = placeId
        saveFavs()
        refreshFavs()
    end
end)

refreshFavs()

-- === Anti AFK ===
local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
   vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
   wait(1)
   vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

-- === Auto Rejoin ===
game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(obj)
    if obj.Name == "ErrorPrompt" then
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
end)
