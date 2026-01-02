--[Key System Module]

local CyberCodersModule = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

local setClipboard = setclipboard or toclipboard
local openBrowser = (syn and syn.openbrowser) or openbrowser

local Platoboost = {}
do
    local service = 16113
    local useNonce = true

    local request = request or http_request or syn_request
    local getHwid = gethwid or function() return lp.UserId end
    local host = "https://api.platoboost.app"

    local function genNonce()
        local s = ""
        for i = 1, 16 do
            s ..= string.char(math.random(97,122))
        end
        return s
    end

    function Platoboost.CopyLink()
        local r = request({
            Url = host .. "/public/start",
            Method = "POST",
            Body = '{"service":'..service..',"identifier":"'..getHwid()..'"}',
            Headers = {["Content-Type"]="application/json"}
        })

        local url = r and r.Body and r.Body:match('"url"%s*:%s*"(.-)"')
        if url then
            setClipboard(url)
        end
    end

    function Platoboost.VerifyKey(key)
        local url = host.."/public/whitelist/"..service
            .."?identifier="..getHwid()
            .."&key="..key

        if useNonce then
            url ..= "&nonce=" .. genNonce()
        end

        local r = request({ Url = url, Method = "GET" })
        if r and r.StatusCode == 200 and r.Body:find('"valid"%s*:%s*true') then
            return true
        end

        if key:sub(1,4) == "KEY_" then
            local redeem = request({
                Url = host .. "/public/redeem/" .. service,
                Method = "POST",
                Body = '{"identifier":"'..getHwid()..'","key":"'..key..'"}',
                Headers = {["Content-Type"]="application/json"}
            })

            if redeem and redeem.StatusCode == 200
            and redeem.Body:find('"valid"%s*:%s*true') then
                return true
            end
        end

        return false
    end
end

function CyberCodersModule.Show(callback)
    callback = callback or function() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CyberCodersKeyUI"
    gui.ResetOnSpawn = false
    gui.Parent = lp:WaitForChild("PlayerGui")

    local main = Instance.new("Frame", gui)
    main.Size = UDim2.fromScale(0.65, 0.82)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = Color3.fromRGB(12, 10, 22)
    main.BorderSizePixel = 0
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 28)

    local stroke = Instance.new("UIStroke", main)
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(170, 90, 255)
    stroke.Transparency = 0.15

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.fromScale(1, 0.18)
    title.BackgroundTransparency = 1
    title.Text = "CyberCoders Menu"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 44
    title.TextColor3 = Color3.fromRGB(190, 120, 255)

    local subtitle = Instance.new("TextLabel", main)
    subtitle.Position = UDim2.fromScale(0, 0.16)
    subtitle.Size = UDim2.fromScale(1, 0.1)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "KEY SYSTEM"
    subtitle.Font = Enum.Font.GothamBold
    subtitle.TextSize = 20
    subtitle.TextColor3 = Color3.fromRGB(215, 180, 255)

    local mascotText = Instance.new("TextLabel", main)
    mascotText.Position = UDim2.fromScale(0.2, 0.52)
    mascotText.Size = UDim2.fromScale(0.6, 0.06)
    mascotText.BackgroundTransparency = 1
    mascotText.Text = "Waiting for the key to be entered..."
    mascotText.Font = Enum.Font.GothamBold
    mascotText.TextSize = 18
    mascotText.TextColor3 = Color3.fromRGB(200,195,225)

    local box = Instance.new("TextBox", main)
    box.Position = UDim2.fromScale(0.1, 0.6)
    box.Size = UDim2.fromScale(0.8, 0.12)
    box.PlaceholderText = "Put Key here"
    box.Font = Enum.Font.Gotham
    box.TextSize = 20
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.BackgroundColor3 = Color3.fromRGB(22,18,40)
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,16)

    local verify = Instance.new("TextButton", main)
    verify.Position = UDim2.fromScale(0.1, 0.74)
    verify.Size = UDim2.fromScale(0.8, 0.11)
    verify.Text = "Execute Script"
    verify.Font = Enum.Font.GothamBold
    verify.TextSize = 22
    verify.TextColor3 = Color3.fromRGB(255,255,255)
    verify.BackgroundColor3 = Color3.fromRGB(135,85,255)
    verify.BorderSizePixel = 0
    Instance.new("UICorner", verify).CornerRadius = UDim.new(0,18)

    local howtoget = Instance.new("TextButton", main)
    howtoget.Position = UDim2.fromScale(0.1, 0.88)
    howtoget.Size = UDim2.fromScale(0.8, 0.08)
    howtoget.Text = "   How to get Key (YouTube)"
    howtoget.Font = Enum.Font.GothamBold
    howtoget.TextSize = 17
    howtoget.TextColor3 = Color3.fromRGB(255,255,255)
    howtoget.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    howtoget.BorderSizePixel = 0
    Instance.new("UICorner", howtoget).CornerRadius = UDim.new(0,16)

    local ytIcon = Instance.new("ImageLabel", howtoget)
    ytIcon.Size = UDim2.fromScale(0.08, 0.6)
    ytIcon.Position = UDim2.fromScale(0.05, 0.5)
    ytIcon.AnchorPoint = Vector2.new(0, 0.5)
    ytIcon.BackgroundTransparency = 1
    ytIcon.Image = "rbxassetid://13825848216" -- YouTube Icon

    howtoget.MouseButton1Click:Connect(function()
        local url = "https://youtu.be/zBuS-86pQUM?si=UvBlxRisDTmAJJav"

        if openBrowser then
            openBrowser(url)
            mascotText.Text = "Opening YouTube video..."
        else
            setClipboard(url)
            mascotText.Text = "Link copied! Paste it in your browser."
        end

        mascotText.TextColor3 = Color3.fromRGB(255, 180, 180)
    end)

    verify.MouseButton1Click:Connect(function()
        if Platoboost.VerifyKey(box.Text) then
            mascotText.Text = "Correct Key! Congratulations"
            mascotText.TextColor3 = Color3.fromRGB(0,255,0)
            task.wait(1.2)
            gui:Destroy()
            callback(true)
        else
            mascotText.Text = "Invalid Key"
            mascotText.TextColor3 = Color3.fromRGB(255,90,90)
        end
    end)
end

return CyberCodersModule
