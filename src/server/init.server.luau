--!strict
-- hackathon-game server entry point. Two-phase bootstrap: init() all systems,
-- then start() all systems. Drop a ModuleScript into Systems/ and it loads automatically.

local Systems = script:FindFirstChild("Systems")

local loaded: { [string]: any } = {}
if Systems then
	for _, child in Systems:GetChildren() do
		if child:IsA("ModuleScript") then
			loaded[child.Name] = require(child)
		end
	end
end

for _, system in loaded do
	if typeof(system.init) == "function" then
		system.init()
	end
end

for _, system in loaded do
	if typeof(system.start) == "function" then
		task.spawn(system.start)
	end
end

print("[hackathon-game] server started")
