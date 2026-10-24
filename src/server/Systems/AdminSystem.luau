--!strict
-- Admin check required by the lobby (SessionService) and ComputerRegistry.

local ADMINS: { [string]: boolean } = {
	woodendraco246 = true,
	hotdogdelivery = true,
	stevejackcarlo = true,
	jasonrobloxt19 = true,
}

local AdminSystem = {}

function AdminSystem.IsAdmin(player: Player): boolean
	return ADMINS[string.lower(player.Name)] == true
end

return AdminSystem
