 FILE 1: DELTA AI CHAT GUI
-- Replace SERVER_URL after publishing ai_server.js to Cloudflare.
-- This displays AI code and never executes generated code automatically.
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local player=Players.LocalPlayer
local env=(getgenv and getgenv()) or _G
if type(env.DeltaAIStop)=="function" then pcall(env.DeltaAIStop) end
local SERVER_URL="https://YOUR-WORKER.YOUR-SUBDOMAIN.workers.dev"
local requestFn=(type(request)=="function" and request)
    or (type(http_request)=="function" and http_request)
    or (type(syn)=="table" and type(syn.request)=="function" and syn.request)
local gui=Instance.new("ScreenGui")
gui.Name="DeltaAIChatV2";gui.ResetOnSpawn=false;gui.DisplayOrder=999
 gui.Parent=player:WaitForChild("PlayerGui")
local function make(class,properties,parent)
    local obj=Instance.new(class)
    for k,v in pairs(properties) do obj[k]=v end
    obj.Parent=parent;return obj
end
local function rounded(obj)
    make("UICorner",{CornerRadius=UDim.new(0,9)},obj)
end
local frame=make("Frame",{
    Size=UDim2.fromOffset(310,430),Position=UDim2.new(.5,-155,.13,0),
    BackgroundColor3=Color3.fromRGB(20,22,32),BorderSizePixel=0,
    Active=true,Draggable=true
},gui)
rounded(frame)
make("UIStroke",{Color=Color3.fromRGB(155,92,255),Thickness=2},frame)
make("TextLabel",{
    Text="REAL AI SCRIPT MAKER",BackgroundTransparency=1,
    Size=UDim2.new(1,-43,0,35),Position=UDim2.fromOffset(10,2),
    TextColor3=Color3.fromRGB(207,181,255),Font=Enum.Font.GothamBold,
    TextSize=16,TextXAlignment=Enum.TextXAlignment.Left
},frame)
local close=make("TextButton",{
    Text="X",Size=UDim2.fromOffset(30,28),Position=UDim2.new(1,-36,0,5),
    BackgroundColor3=Color3.fromRGB(78,43,91),TextColor3=Color3.new(1,1,1)
},frame);rounded(close)
local function textbox(y,h,placeholder)
    local b=make("TextBox",{
        Text="",PlaceholderText=placeholder,ClearTextOnFocus=false,
        MultiLine=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.Code,TextSize=13,
        TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(39,41,57),
        Size=UDim2.new(1,-20,0,h),Position=UDim2.fromOffset(10,y)
    },frame);rounded(b);return b
end
local token=textbox(42,32,"Your private access code (NOT API key)")
local prompt=textbox(80,82,"Describe what Roblox script you want...")
local send=make("TextButton",{
    Text="ASK AI / GENERATE",Size=UDim2.new(1,-20,0,37),
    Position=UDim2.fromOffset(10,169),BackgroundColor3=Color3.fromRGB(107,66,220),
    TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=14
},frame);rounded(send)
local status=make("TextLabel",{
    Text="Ready. Deploy your AI server first.",BackgroundTransparency=1,
    Size=UDim2.new(1,-20,0,20),Position=UDim2.fromOffset(10,210),
    TextColor3=Color3.fromRGB(194,194,208),TextSize=11
},frame)
local output=textbox(234,145,"AI response appears here")
output.Text="AI-generated code appears here. It will not run automatically."
local copy=make("TextButton",{
    Text="COPY RESPONSE",Size=UDim2.new(1,-20,0,34),
    Position=UDim2.fromOffset(10,385),BackgroundColor3=Color3.fromRGB(43,94,73),
    TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=13
},frame);rounded(copy)
local alive,busy=true,false
local conns={}
local function listen(signal,fn)
    local c=signal:Connect(fn);table.insert(conns,c)
end
listen(send.Activated,function()
    if busy or not alive then return end
    if SERVER_URL:find("YOUR%-WORKER") then status.Text="Set SERVER_URL in chat.lua first";return end
    if not requestFn then status.Text="This executor has no HTTP request function";return end
    if #prompt.Text<3 or token.Text=="" then status.Text="Enter your request and access code";return end
    busy=true;send.Text="GENERATING...";status.Text="Contacting the real AI..."
    local message=prompt.Text
    local accessCode=token.Text
    task.spawn(function()
        local ok,res=pcall(requestFn,{
            Url=SERVER_URL,Method="POST",
            Headers={["Content-Type"]="application/json",["X-Access-Token"]=accessCode},
            Body=Http:JSONEncode({prompt=message})
        })
        if not alive then return end
        if not ok then
            status.Text="Network error: "..tostring(res):sub(1,70)
        else
            local decoded,payload=pcall(function()return Http:JSONDecode(res.Body or "")end)
            if not decoded then status.Text="Invalid reply from server"
            elseif type(payload.answer)=="string" then
                output.Text=payload.answer;status.Text="Done! Review code before running."
            else status.Text="AI error: "..tostring(payload.error or res.StatusCode):sub(1,80) end
        end
        busy=false;send.Text="ASK AI / GENERATE"
    end)
end)
listen(copy.Activated,function()
    local clipboard=(type(setclipboard)=="function" and setclipboard)
        or (type(toclipboard)=="function" and toclipboard)
    if clipboard then
        local ok=pcall(clipboard,output.Text)
        status.Text=ok and "Copied to clipboard" or "Copy failed"
    else status.Text="Select the response text and copy it" end
end)
env.DeltaAIStop=function()
    if not alive then return end
    alive=false
    for _,c in ipairs(conns) do c:Disconnect() end
    gui:Destroy();env.DeltaAIStop=nil
end
listen(close.Activated,env.DeltaAIStop)
print("DELTA AI CHAT: connect chat.lua to your Worker URL")