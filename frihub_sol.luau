--// FriHub Ultimate AI Egg Macro
--// Full Fixed Version

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
	"_egg",
}

local AUTO_FARM = false

local GRID_SIZE = 8
local SAVE_FILE = "FriHub_AI_Memory.json"

--========================
-- AI MEMORY
--========================

local Memory = {}
local PathMemory = {}
local DangerZones = {}
local CollectedTargets = {}

local CollectedEggs = 0

local function key(pos)
	return math.floor(pos.X / GRID_SIZE) .. "|" .. math.floor(pos.Z / GRID_SIZE)
end

local function learnPath(pos)

	local k = key(pos)

	if not PathMemory[k] then
		PathMemory[k] = 0
	end

	PathMemory[k] += 1
end

local function rememberDanger(pos,amount)

	local k = key(pos)

	if not DangerZones[k] then
		DangerZones[k] = 0
	end

	DangerZones[k] += amount
end

--========================
-- SAVE / LOAD
--========================

local function saveAI()

	if writefile then

		local data = {
			PathMemory = PathMemory,
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

				PathMemory = data.PathMemory or {}
				DangerZones = data.DangerZones or {}

				sendWebhook(
					"📂 AI Loaded",
					"Previous memory loaded",
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
stats.Text = "Eggs: 0"
stats.TextColor3 = Color3.new(1,1,1)
stats.Font = Enum.Font.Gotham
stats.TextSize = 14
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
-- SAFE MOVE (追加ここ)
--========================

local function isGroundAhead(fromPos, direction)
	local origin = fromPos + Vector3.new(0, 3, 0)

	local castDir = direction.Unit * 6

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Blacklist

	-- ① 前方チェック（壁）
	local front = workspace:Raycast(origin, castDir, params)

	if not front then
		return false
	end

	-- ② 足元チェック（穴）
	local down = workspace:Raycast(
		origin + castDir,
		Vector3.new(0, -20, 0),
		params
	)

	if not down then
		return false
	end

	-- ③ 高低差チェック（落差防止）
	if (down.Position.Y < fromPos.Y - 8) then
		return false
	end

	return true
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


end

for _,v in pairs(workspace:GetDescendants()) do

	if isTarget(v.Name) then
		createESP(v)
	end
end
--========================
-- ESP UPDATE LOOP（これ1個だけ）
--========================

RunService.RenderStepped:Connect(function()

    for _, obj in pairs(workspace:GetDescendants()) do

        if obj:FindFirstChild("FriESPTag") then

            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then

                local dist = math.floor((root.Position - part.Position).Magnitude)

                local bill = obj:FindFirstChildWhichIsA("BillboardGui", true)
                if bill then

                    local txt = bill:FindFirstChildWhichIsA("TextLabel", true)
                    if txt then
                        txt.Text = obj.Name .. "\n" .. dist .. "m"
                    end
                end
            end
        end
    end
end)
workspace.DescendantAdded:Connect(function(v)

	task.wait(0.2)

	if isTarget(v.Name) then
		createESP(v)
	end
end)

--========================
-- CLOSEST EGG
--========================

local function getClosestEgg()

	local closest = nil
	local closestModel = nil
	local shortest = math.huge

	for _,v in pairs(workspace:GetDescendants()) do

		if isTarget(v.Name) then

			local part = getBasePart(v)

			if part
			and not CollectedTargets[v]
			then

				local dist =
					(root.Position - part.Position).Magnitude

				if dist < shortest then

					shortest = dist
					closest = part
					closestModel = v
				end
			end
		end
	end

	return closest,closestModel
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
task.wait(5)
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

local function walkTo(target,targetModel)

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

		-- 落下検知

		if root.Position.Y < -10 then

			root.CFrame =
				CFrame.new(0,20,0)

			sendWebhook(
				"💀 Fall Detected",
				"Player fell under map",
				16711680
			)
		end

		local dist =
			(root.Position - target.Position).Magnitude

		-- 到着距離

		if dist <= 5 then
			break
		end

		-- スタック検知

		if math.abs(dist - lastDist) < 1 then
			stuck += 0.05
		else
			stuck = 0
		end

		lastDist = dist

		-- スタック処理

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

		-- 移動位置改善

-- 移動位置改善（横回避版）

local toTarget = target.Position - root.Position
toTarget = Vector3.new(toTarget.X, 0, toTarget.Z)

-- 方向がゼロになるバグ防止
if toTarget.Magnitude < 0.5 then
    return
end

local dir = toTarget.Unit

-- 前方が危険なら横に逃げる
-- 安定横回避（方向固定版）
if _G.lastSafeDir == nil then
    _G.lastSafeDir = dir
end

local function getSafeDir(baseDir)

    local right = Vector3.new(baseDir.Z, 0, -baseDir.X)
    local left = -right

    -- まず前回の方向を優先（ブレ防止）

    -- 次に右
local function getSafeDir(baseDir)

    local right = Vector3.new(baseDir.Z, 0, -baseDir.X)
    local left = -right

    if isGroundAhead(root.Position, baseDir) then
        return baseDir
    end

    if isGroundAhead(root.Position, right) then
        return right
    end

    if isGroundAhead(root.Position, left) then
        return left
    end

    return baseDir -- 最悪でも逆走しない
end

    -- 次に左
    if isGroundAhead(root.Position, left) then
        return left
    end

    -- 最悪後退
    return -dir
end

dir = getSafeDir(dir)
_G.lastSafeDir = dir

local movePos = root.Position + dir * 6
humanoid:MoveTo(movePos)

		-- 壁ジャンプ

		local rayParams = RaycastParams.new()

		rayParams.FilterDescendantsInstances = {
			character
		}

		rayParams.FilterType =
			Enum.RaycastFilterType.Blacklist

local result = workspace:Raycast(

    root.Position,

    root.CFrame.LookVector * 8,

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

		task.wait(0.1)

	until false

	humanoid:MoveTo(root.Position)


CollectedTargets[targetModel] = true

pressE()

task.wait(1.5)

CollectedTargets[targetModel] = nil
end

--========================
-- LOOP
--========================

task.spawn(function()

	while true do

		task.wait(0.2)

		if AUTO_FARM then

			local egg,model = getClosestEgg()

if egg then
	walkTo(egg,model)
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
