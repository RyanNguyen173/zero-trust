--!strict

local Players = game:GetService("Players")

local Hello = {}

local function onPlayerAdded(player: Player): ()
	print(string.format("Hello, %s", player.Name))
end

function Hello.start(): ()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return Hello
