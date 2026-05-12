--// FriHub - Smart _egg Auto Farm
--// REAL JUMP FIX VERSION

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

--========================
-- SETTINGS
--========================

local TARGET_NAMES = {
	"_egg"
}

local AUTO_FARM = false

--========================
-- GUI
--========================

local gui = Instance.new("ScreenGui")
gui.Name = "FriHubEggFarm"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,230,0,90)
frame.Position = UDim2.new(0,30,0.4,0)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

Instance.new("UICorner", frame)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundTransparency = 1
title.Text = "FriHub Egg Farm"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0.85,0,0,35)
toggle.Position = UDim2.new(0.075,0,0.5,0)
toggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggle.Text = "AUTO FARM : OFF"
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 16
toggle.Parent = frame

Instance.new("UICorner", toggle)

toggle.MouseButton1Click:Connect(function()

	AUTO_FARM = not AUTO_FARM

	if AUTO_FARM then
		toggle.Text = "AUTO FARM : ON"
		toggle.BackgroundColor3 = Color3.fromRGB(0,170,80)
	else
		toggle.Text = "AUTO FARM : OFF"
		toggle.BackgroundColor3 = Color3.fromRGB(40,40,40)

		humanoid:MoveTo(root.Position)
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
		return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
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

local function createESP(obj)

	if obj:FindFirstChild("FriESP") then
		return
	end

	local part = getBasePart(obj)

	if not part then
		return
	end

	local h = Instance.new("Highlight")
	h.Name = "FriESP"
	h.FillColor = Color3.fromRGB(255,255,0)
	h.OutlineColor = Color3.new(1,1,1)
	h.FillTransparency = 0.35
	h.Parent = obj

	local bill = Instance.new("BillboardGui")
	bill.Name = "FriDistance"
	bill.Size = UDim2.new(0,120,0,40)
	bill.AlwaysOnTop = true
	bill.StudsOffset = Vector3.new(0,3,0)
	bill.Parent = part

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1,0,1,0)
	txt.BackgroundTransparency = 1
	txt.TextColor3 = Color3.new(1,1,1)
	txt.TextStrokeTransparency = 0
	txt.Font = Enum.Font.GothamBold
	txt.TextScaled = true
	txt.Parent = bill

	RunService.RenderStepped:Connect(function()

		if not part or not part.Parent then
			return
		end

		local dist =
			math.floor(
				(root.Position - part.Position).Magnitude
			)

		txt.Text =
			"["..obj.Name.."]\n"..dist.."m"
	end)
end

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
end

--========================
-- WALK
--========================

local function walkTo(target)

	if not target or not target.Parent then
		return
	end

	local stuckTimer = 0
	local lastDistance = math.huge

	repeat

		if not AUTO_FARM then
			return
		end

		if not target.Parent then
			return
		end

		local targetPos = target.Position

		local dist =
			(root.Position - targetPos).Magnitude

		if dist <= 6 then
			break
		end

		--========================
		-- スタック検知
		--========================

		if math.abs(dist - lastDistance) < 1 then
			stuckTimer += 0.03
		else
			stuckTimer = 0
		end

		lastDistance = dist

		--========================
		-- 引っかかった
		--========================

		if stuckTimer >= 1 then

			humanoid:ChangeState(
				Enum.HumanoidStateType.Jumping
			)

			local backPos =
				root.Position
				- root.CFrame.LookVector * 10

			humanoid:MoveTo(backPos)

			task.wait(0.8)

			local bestPos = nil
			local bestScore = math.huge

			local angles = {
				-120,-90,-60,-45,-30,
				30,45,60,90,120,180
			}

			for _,angle in pairs(angles) do

				local dir =
					(CFrame.Angles(
						0,
						math.rad(angle),
						0
					) * root.CFrame).LookVector

				local rayParams =
					RaycastParams.new()

				rayParams.FilterDescendantsInstances = {
					character
				}

				rayParams.FilterType =
					Enum.RaycastFilterType.Blacklist

				local result = workspace:Raycast(
					root.Position,
					dir * 10,
					rayParams
				)

				if not result then

					local testPos =
						root.Position + dir * 12

					local score =
						(testPos - targetPos).Magnitude

					if score < bestScore then
						bestScore = score
						bestPos = testPos
					end
				end
			end

			if bestPos then

				humanoid:MoveTo(bestPos)

				task.wait(1)

			else

				for i = 1,3 do

					humanoid:ChangeState(
						Enum.HumanoidStateType.Jumping
					)

					humanoid:MoveTo(
						root.Position
						+ root.CFrame.LookVector * 5
					)

					task.wait(0.25)
				end
			end

			stuckTimer = 0
		end

		--========================
		-- LOOK
		--========================

		local lookPos = Vector3.new(
			targetPos.X,
			root.Position.Y,
			targetPos.Z
		)

		root.CFrame = CFrame.lookAt(
			root.Position,
			lookPos
		)

		--========================
		-- MOVE
		--========================

		humanoid:MoveTo(targetPos)

		--========================
		-- REAL JUMP FIX
		--========================

		if humanoid.FloorMaterial ~= Enum.Material.Air then

			humanoid:ChangeState(
				Enum.HumanoidStateType.Jumping
			)

			humanoid:Move(
				Vector3.new(0,0,-1),
				true
			)
		end

		task.wait(0.03)

	until false

	humanoid:MoveTo(root.Position)

	-- 回収
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

			if egg and egg.Parent then
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
