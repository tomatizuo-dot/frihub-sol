--// FriHub Ultimate AI Farm
--// ESP + AI + Route Learning + Visual + Egg Fix + Webhook

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

--========================
-- WEBHOOK
--========================

local WEBHOOK_URL = "https://discord.com/api/webhooks/1503768410247663796/pwwiqIiiTf5ZNUhqW7_rLkKhkk5J4aojFroclLAYzExo-AMisIs55gBxgI57O9nD2D12"

local function sendWebhook(title,description,color)

	if WEBHOOK_URL == "" then
		return
	end

	if not request then
		return
	end

	request({
		Url = WEBHOOK_URL,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode({
			embeds = {{
				title = title,
				description = description,
				color = color,
				footer = {
					text = "FriHub AI"
				}
			}}
		})
	})
end

sendWebhook(
	"🟢 AI Started",
	"FriHub launched",
	65280
)

--========================
-- SETTINGS
--========================

local TARGET_NAMES = {
	"_egg"
}

local AUTO_FARM = false

local GRID_SIZE = 8
local SAVE_FILE = "FriHub_AI_Memory.json"

--========================
-- AI MEMORY
--========================

local Memory = {}
local Walls = {}
local PathMemory = {}
local JumpMemory = {}
local DangerZones = {}

local CollectedEggs = 0

--========================
-- SAVE / LOAD
--========================

local function saveAI()

	if writefile then

		local data = {
			Memory = Memory,
			Walls = Walls,
			PathMemory = PathMemory,
			JumpMemory = JumpMemory,
			DangerZones = DangerZones
		}

		writefile(
			SAVE_FILE,
			HttpService:JSONEncode(data)
		)

		sendWebhook(
			"💾 AI Saved",
			"Learning data saved",
			65280
		)
	end
end

local function loadAI()

	if readfile and isfile then

		if isfile(SAVE_FILE) then

			local raw = readfile(SAVE_FILE)

			local success,data = pcall(function()
				return HttpService:JSONDecode(raw)
			end)

			if success and data then

				Memory = data.Memory or {}
				Walls = data.Walls or {}
				PathMemory = data.PathMemory or {}
				JumpMemory = data.JumpMemory or {}
				DangerZones = data.DangerZones or {}

				sendWebhook(
					"📂 AI Loaded",
					"AI memory loaded",
					3447003
				)
			end
		end
	end
end

loadAI()

--========================
-- GUI
--========================

local gui = Instance.new("ScreenGui")
gui.Name = "FriHubAI"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,260,0,130)
frame.Position = UDim2.new(0,30,0.4,0)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

Instance.new("UICorner",frame)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundTransparency = 1
title.Text = "FriHub egg macro"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0.85,0,0,35)
toggle.Position = UDim2.new(0.075,0,0.38,0)
toggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggle.Text = "AUTO FARM : OFF"
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 16
toggle.Parent = frame

Instance.new("UICorner",toggle)

local stats = Instance.new("TextLabel")
stats.Size = UDim2.new(1,0,0,30)
stats.Position = UDim2.new(0,0,0.72,0)
stats.BackgroundTransparency = 1
stats.TextColor3 = Color3.new(1,1,1)
stats.Font = Enum.Font.Gotham
stats.TextSize = 14
stats.Text = "Eggs: 0"
stats.Parent = frame

toggle.MouseButton1Click:Connect(function()

	AUTO_FARM = not AUTO_FARM

	if AUTO_FARM then

		toggle.Text = "AUTO FARM : ON"

		toggle.BackgroundColor3 =
			Color3.fromRGB(0,170,80)

		sendWebhook(
			"🟢 Auto Farm",
			"Enabled",
			65280
		)

	else

		toggle.Text = "AUTO FARM : OFF"

		toggle.BackgroundColor3 =
			Color3.fromRGB(40,40,40)

		humanoid:MoveTo(root.Position)

		saveAI()

		sendWebhook(
			"🔴 Auto Farm",
			"Disabled",
			16711680
		)
	end
end)

--========================
-- TARGET CHECK
--========================

local function isTarget(name)

	local lower = string.lower(name)

	for _,v in pairs(TARGET_NAMES) do

		if string.find(lower,string.lower(v)) then
			return true
		end
	end

	return false
end

--========================
-- GET BASEPART
--========================

local function getBasePart(obj)

	if obj:IsA("BasePart") then
		return obj
	end

	if obj:IsA("Model") then

		return obj.PrimaryPart
			or obj:FindFirstChildWhichIsA("BasePart")
	end

	for _,v in pairs(obj:GetDescendants()) do

		if v:IsA("BasePart") then
			return v
		end
	end
end

--========================
-- ESP
--========================

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "FriHub_ESP"
ESPFolder.Parent = game.CoreGui

local function createESP(obj)

	if obj:FindFirstChild("FriESPTag") then
		return
	end

	local part = getBasePart(obj)

	if not part then
		return
	end

	local tag = Instance.new("BoolValue")
tag.Name = "FriESPTag"
	tag.Parent = obj

	local highlight = Instance.new("Highlight")

	highlight.Name = "FriESP"

	highlight.FillColor =
		Color3.fromRGB(255,255,0)

	highlight.OutlineColor =
		Color3.fromRGB(255,255,255)

	highlight.FillTransparency = 0.35

	highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	highlight.Adornee = obj

	highlight.Parent = ESPFolder

	local bill = Instance.new("BillboardGui")

	bill.Size = UDim2.new(0,120,0,40)

	bill.AlwaysOnTop = true

	bill.StudsOffset = Vector3.new(0,3,0)

	bill.Adornee = part

	bill.Parent = ESPFolder

	local txt = Instance.new("TextLabel")

	txt.Size = UDim2.new(1,0,1,0)

	txt.BackgroundTransparency = 1

	txt.TextColor3 = Color3.new(1,1,1)

	txt.TextStrokeTransparency = 0

	txt.Font = Enum.Font.GothamBold

	txt.TextScaled = true

	txt.Parent = bill

	RunService.RenderStepped:Connect(function()

		if not obj.Parent
		or not part.Parent
		then
			highlight:Destroy()
			bill:Destroy()
			return
		end

		local dist =
			math.floor(
				(root.Position - part.Position).Magnitude
			)

		txt.Text =
			obj.Name
			.. "\n"
			.. dist
			.. "m"
	end)
end

--========================
-- ESP SCAN
--========================

local function scanESP()

	for _,v in pairs(workspace:GetDescendants()) do

		if isTarget(v.Name) then
			createESP(v)
		end
	end
end

scanESP()

workspace.DescendantAdded:Connect(function(v)

	task.wait(0.2)

	if isTarget(v.Name) then
		createESP(v)
	end
end)

--========================
-- GET CLOSEST EGG
--========================

local function getClosestEgg()

	local closest = nil
	local shortest = math.huge

	for _,v in pairs(workspace:GetDescendants()) do

		if isTarget(v.Name) then

			local part = getBasePart(v)

			if part
			and part:IsDescendantOf(workspace)
			then

				local dist =
					(root.Position - part.Position).Magnitude

				if dist < shortest then

					shortest = dist
					closest = part
				end
			end
		end
	end

	return closest
end

--========================
-- PRESS E
--========================

local function pressE()

	for i = 1,3 do

		VirtualInputManager:SendKeyEvent(
			true,
			Enum.KeyCode.E,
			false,
			game
		)

		task.wait(0.05)

		VirtualInputManager:SendKeyEvent(
			false,
			Enum.KeyCode.E,
			false,
			game
		)

		task.wait(0.1)
	end

	CollectedEggs += 1

	stats.Text =
		"Eggs: "
		.. CollectedEggs

	sendWebhook(
		"🥚 Egg Collected",
		"Total Eggs: "
		.. CollectedEggs,
		3447003
	)
end

--========================
-- VISUAL
--========================

local function drawPoint(pos,color,size,time)

	local p = Instance.new("Part")

	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon

	p.Size = Vector3.new(size,size,size)

	p.Color = color

	p.Position = pos + Vector3.new(0,0.2,0)

	p.Parent = workspace

	Debris:AddItem(p,time or 10)
end

--========================
-- WALK
--========================

local function walkTo(target)

	if not target then
		return
	end

	local stuck = 0
	local lastDist = math.huge

	repeat

		if not AUTO_FARM then
			return
		end

		if not target.Parent then
			return
		end

		local dist =
			(root.Position - target.Position).Magnitude

		if dist <= 12 then
			break
		end

		if math.abs(dist - lastDist) < 1 then
			stuck += 0.05
		else
			stuck = 0
		end

		lastDist = dist

		if stuck >= 1 then

			rememberDanger(root.Position,5)

			drawPoint(
				root.Position,
				Color3.fromRGB(255,0,0),
				1,
				10
			)

			humanoid:ChangeState(
	Enum.HumanoidStateType.Jumping
)

root.Velocity =
	Vector3.new(
		root.Velocity.X,
		55,
		root.Velocity.Z
	)

			sendWebhook(
				"⚠️ Stuck",
				"AI stuck detected",
				16711680
			)

			stuck = 0
		end

		humanoid:MoveTo(target.Position)
local rayParams = RaycastParams.new()

rayParams.FilterDescendantsInstances = {
	character
}

rayParams.FilterType =
	Enum.RaycastFilterType.Blacklist

local result = workspace:Raycast(
	root.Position,
	root.CFrame.LookVector * 4,
	rayParams
)

if result then

	humanoid:ChangeState(
		Enum.HumanoidStateType.Jumping
	)

	root.Velocity =
		Vector3.new(
			root.Velocity.X,
			55,
			root.Velocity.Z
		)
end

		learnPath(root.Position)

		task.wait(0.05)

	until false

	humanoid:MoveTo(root.Position)

	pressE()

	task.wait(0.5)
end

--========================
-- LOOP
--========================

task.spawn(function()

	while true do

		task.wait(0.2)

		if AUTO_FARM then

			local egg = getClosestEgg()

			if egg then
				walkTo(egg)
			end
		end
	end
end)

--========================
-- CHARACTER UPDATE
--========================

player.CharacterAdded:Connect(function(char)

	character = char

	humanoid =
		character:WaitForChild("Humanoid")

	root =
		character:WaitForChild(
			"HumanoidRootPart"
		)
end)
