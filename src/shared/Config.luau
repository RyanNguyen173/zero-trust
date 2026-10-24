--!strict
-- Tunable gameplay values. NOTE: replicated to clients — nothing secret here,
-- and the server never trusts a client-reported value from this file.

return table.freeze({
	AUTOSAVE_INTERVAL = 60,

	START_BUDGET = 25_000,
	FALSE_REJECT_PENALTY = 500,
	ESCALATE_TIME_MINUTES = 10,

	SHIFT_START_MINUTES = 9 * 60,
	SHIFT_END_MINUTES = 17 * 60,

	GAME_MINUTES_PER_REAL_SECOND = 6,
	TICKET_SPAWN_INTERVAL_SEC = 6,

	-- Uploaded directly (not the catalog decal id, which failed to load in this place).
	WALLPAPER_ASSET_ID = "rbxassetid://125725714752013",

	-- Restored from the lobby system's Config (it was overwritten by Rojo sync).
	LEVELS = {
		{ stage = "BakeryLevel", name = "The Daily Loaf", entrance = Vector3.new(119.3, 4, 44.5) },
		{ stage = "GameCompanyLevel", name = "Nova Games", entrance = Vector3.new(12, 4, -28) },
		{ stage = "OmniHealthLevel", name = "OmniHealth", entrance = Vector3.new(372, 4, -42) },
		{
			stage = "PulseLogisticsLevel",
			name = "Pulse Logistics",
			entrance = Vector3.new(193, 4, -51),
		},
		{
			stage = "DefenseCommandLevel",
			name = "Defense & Aerospace Command",
			entrance = Vector3.new(40, 4, 465),
		},
	},

	DAY_QUOTAS = {
		{ minProcessed = 5, minScams = 2 },
		{ minProcessed = 6, minScams = 2 },
		{ minProcessed = 7, minScams = 3 },
		{ minProcessed = 8, minScams = 3 },
		{ minProcessed = 9, minScams = 4 },
	},

	COMPANY_DIRECTORY = {
		staff = {
			{
				name = "John Harrington",
				title = "CEO",
				email = "ceo@company.com",
				phone = "Ext. 101",
			},
			{
				name = "Alex Chen",
				title = "IT Lead",
				email = "it-support@company.com",
				phone = "Ext. 112",
			},
			{
				name = "Sarah Jenkins",
				title = "CFO",
				email = "s.jenkins@company.com",
				phone = "Ext. 104",
			},
		},
		vendors = {
			{
				name = "Acme Supplies Co.",
				email = "billing@acme-supplies.com",
				routing = "021000021",
				account = "****-4920",
			},
			{
				name = "Global Parts Corp.",
				email = "ap@globalparts.co",
				routing = "122000496",
				account = "****-8812",
			},
		},
	},
})
