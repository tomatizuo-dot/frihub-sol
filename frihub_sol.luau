--// FriHub Ultimate AI Farm
--// Full AI + Visual + Webhook

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

local function sendWebhook(
	title,
	description,
	color
)

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
local RouteHistory = {}

local CollectedEggs = 0

--========================
-- VISUAL
--========================

local VisualFolder =
	Instance.new("Folder")

VisualFolder.Name = "FriHub_AI_Visual"

VisualFolder.Parent = workspace

local RouteFolder =
	Instance.new("Folder")

RouteFolder.Name = "FriHub_Routes"

RouteFolder.Parent = workspace

local LastPoint = nil

--========================
-- GRID
--========================

local function key(pos)

	return
		math.floor(pos.X / GRID_SIZE)
		.."|"
		..
		math.floor(pos.Z / GRID_SIZE)
end

--========================
-- MEMORY
--========================

local function addScore(pos,value)

	local k = key(pos)

	if not Memory[k] then
		Memory[k] = 0
	end

	Memory[k] += value
end

local function getScore(pos)

	return Memory[key(pos)] or 0
end

--========================
-- WALLS
--========================

local function rememberWall(pos)

	Walls[key(pos)] = true
end

local function isWall(pos)

	return Walls[key(pos)] == true
end

--========================
-- ROUTES
--========================

local function learnPath(pos)

	local k = key(pos)

	if not PathMemory[k] then
		PathMemory[k] = 0
	end

	PathMemory[k] += 1
end

local function getPathScore(pos)

	return PathMemory[key(pos)] or 0
end

--========================
-- JUMP MEMORY
--========================

local function rememberJump(pos)

	JumpMemory[key(pos)] = true
end

local function shouldJump(pos)

	return JumpMemory[key(pos)] == true
end

--========================
-- DANGER
--========================

local function rememberDanger(pos,amount)

	local k = key(pos)

	if not DangerZones[k] then
		DangerZones[k] = 0
	end

	DangerZones[k] += amount
end

local function getDanger(pos)

	return DangerZones[key(pos)] or 0
end

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
					"Previous AI loaded",
					3447003
				)
			end
		end
	end
end

loadAI()

--========================
-- VISUAL DRAW
--========================

local function drawPoint(pos,color,size,time)

	local p = Instance.new("Part")

	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon

	p.Size = Vector3.new(size,size,size)

	p.Color = color

	p.Position = pos + Vector3.new(0,0.2,0)

	p.Parent = VisualFolder

	Debris:AddItem(p,time or 15)
end

local function drawDanger(pos)

	drawPoint(
		pos,
		Color3.fromRGB(255,0,0),
		1.2,
		20
	)
end

local function drawSafe(pos)

	drawPoint(
		pos,
		Color3.fromRGB(0,255,0),
		0.5,
		10
	)
end

local function drawJump(pos)

	drawPoint(
		pos,
		Color3.fromRGB(255,255,0),
		0.8,
		15
	)
end

--========================
-- ROUTE LINE
--========================

local function drawRoute(movePos)

	if LastPoint then

		local dist =
			(movePos - LastPoint).Magnitude

		local line =
			Instance.new("Part")

		line.Anchored = true
		line.CanCollide = false
		line.Material = Enum.Material.Neon

		line.Size =
			Vector3.new(
				0.25,
				0.25,
				dist
			)

		line.CFrame =
			CFrame.lookAt(
				LastPoint,
				movePos
			)
			* CFrame.new(0,0,-dist/2)

		line.Color =
			Color3.fromRGB(0,255,0)

		line.Parent = RouteFolder

		Debris:AddItem(line,20)
	end

	LastPoint = movePos
end

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
title.Text = "FriHub Ultimate AI"
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

	else

		toggle.Text = "AUTO FARM : OFF"

		toggle.BackgroundColor3 =
			Color3.fromRGB(40,40,40)

		humanoid:MoveTo(root.Position)

		saveAI()
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
-- CLOSEST EGG
--========================

local function getClosestEgg()

	local closest = nil
	local shortest = math.huge

	for _,v in pairs(workspace:GetDescendants()) do

		if isTarget(v.Name) then

			local part = getBasePart(v)

			if part then

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
