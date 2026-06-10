-- WorldSignBuilder
-- Помощники создания знаков/табличек с текстом.
-- Используется для подписей зон ("Лесная зона", "Каменистый проход", "Лагерь", "Аванпост").

local PartFactory = require(script.Parent.WorldPartFactory)

local WorldSignBuilder = {}

-- Создаёт модель знака с двумя столбами, доской и текстовой SurfaceGui.
function WorldSignBuilder.createTextSign(name, text, position, parent)
	local signModel = Instance.new("Model")
	signModel.Name = name
	signModel.Parent = parent

	PartFactory.createPart(
		"LeftPost",
		Vector3.new(0.35, 3, 0.35),
		position + Vector3.new(-2.2, -1, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	PartFactory.createPart(
		"RightPost",
		Vector3.new(0.35, 3, 0.35),
		position + Vector3.new(2.2, -1, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	local board = PartFactory.createPart(
		"Board",
		Vector3.new(5.5, 1.8, 0.4),
		position + Vector3.new(0, 0.8, 0),
		Color3.fromRGB(230, 195, 115),
		signModel
	)

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "TextSurface"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "TextLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(55, 35, 20)
	label.Parent = surfaceGui

	return signModel
end

return WorldSignBuilder
