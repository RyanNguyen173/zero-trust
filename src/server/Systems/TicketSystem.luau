--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Types = require(Shared:WaitForChild("Types"))
local EmailDatabase = require(Shared:WaitForChild("EmailDatabase"))

type Ticket = Types.Ticket
type ClientTicket = Types.ClientTicket
type GameState = Types.GameState
type DecisionType = Types.DecisionType
type Phase = Types.Phase
type Quota = Types.Quota
type ShiftSummary = Types.ShiftSummary

local TicketSystem = {}

local function getQuotaForDay(day: number): Quota
	local quotas = Config.DAY_QUOTAS
	local entry = quotas[math.clamp(day, 1, #quotas)]
	return { minProcessed = entry.minProcessed, minScams = entry.minScams }
end

local phase: Phase = "Lobby"
local currentDay: number = 1
local budget: number = Config.START_BUDGET
local shiftMinutes: number = Config.SHIFT_START_MINUTES
local tickets: { [string]: Ticket } = {}
local rejectedTickets: { [string]: Ticket } = {}
local quota: Quota = getQuotaForDay(currentDay)
local lastSummary: ShiftSummary? = nil

local shiftLog = {
	processed = 0,
	caught = 0,
	missed = 0,
	falseRejections = 0,
	scamLosses = 0,
	falseRejectPenalties = 0,
}

local hasSpawnedScriptedEmailThisShift = false

local gameStateSync: RemoteEvent
local submitDecision: RemoteEvent
local startShift: RemoteEvent
local nextDay: RemoteEvent

local GUIDELINES: { string } = {
	"Gift Cards: Never a legitimate payment method -- always reject these requests.",
	"Look-alike domains: check sender spelling carefully (e.g. cornpany.com vs company.com).",
	"Urgency & secrecy: real requests don't demand silence or an immediate wire transfer.",
	"Bank changes: verify by phone before updating any vendor payment details.",
	"Suspicious links: check the real domain before clicking or logging in.",
}

local TIER_NAMES: { string } = {
	"Crumb & Crust Bakery",
	"Apex Indie Game Studio",
	"Pulse Logistics",
	"OmniHealth BioPharma",
	"Federal Aerospace Depot",
}

local function tierForDay(day: number): number
	return math.clamp(math.ceil(day / 5), 1, #TIER_NAMES)
end

local function emailToTicket(email: any): Ticket
	return {
		id = HttpService:GenerateGUID(false),
		ticketType = email.ticketType,
		sender = email.sender,
		message = email.body,
		amount = email.amount,
		tells = email.tells or {},
		isScam = email.isScam,
	}
end

local function generateTicket(isFirstOfShift: boolean): Ticket
	local tier = tierForDay(currentDay)
	local email = nil

	if isFirstOfShift then
		email = EmailDatabase.getShiftScenario(currentDay)
	end
	if not email then
		email = EmailDatabase.getRandomByTier(tier)
	end
	if not email then
		email = EmailDatabase.getRandomByTier(1)
	end

	return emailToTicket(email)
end

local function toClientTicket(ticket: Ticket): ClientTicket
	return {
		id = ticket.id,
		ticketType = ticket.ticketType,
		sender = ticket.sender,
		message = ticket.message,
		amount = ticket.amount,
	}
end

local function buildGameState(): GameState
	local clientTickets: { ClientTicket } = {}
	for _, ticket in tickets do
		table.insert(clientTickets, toClientTicket(ticket))
	end
	return {
		phase = phase,
		day = currentDay,
		tierName = TIER_NAMES[tierForDay(currentDay)],
		shiftMinutes = shiftMinutes,
		tickets = clientTickets,
		quota = quota,
		lastSummary = lastSummary,
		guidelines = GUIDELINES,
	}
end

local function broadcastState(): ()
	gameStateSync:FireAllClients(buildGameState())
end

local function endShift(): ()
	local quotaPassed = shiftLog.processed >= quota.minProcessed
		and shiftLog.caught >= quota.minScams
	lastSummary = {
		processed = shiftLog.processed,
		caught = shiftLog.caught,
		missed = shiftLog.missed,
		falseRejections = shiftLog.falseRejections,
		scamLosses = shiftLog.scamLosses,
		falseRejectPenalties = shiftLog.falseRejectPenalties,
		budgetLeft = budget,
		quotaPassed = quotaPassed,
	}
	phase = if budget <= 0 then "GameOver" else "Summary"
	tickets = {}
	broadcastState()
end

local function processDecision(_player: Player, ticketId: string, decision: DecisionType): ()
	if phase ~= "InShift" then
		return
	end

	local ticket = tickets[ticketId]
	local isRescue = false
	if not ticket then
		ticket = rejectedTickets[ticketId]
		if ticket and decision == "Approve" then
			isRescue = true
		else
			return
		end
	end

	if decision == "Approve" then
		if ticket.isScam then
			local amount = ticket.amount or 0
			budget -= amount
			shiftLog.missed += 1
			shiftLog.scamLosses += amount
			if isRescue then
				shiftLog.caught = math.max(0, shiftLog.caught - 1)
			end
		end
	elseif decision == "Reject" then
		if ticket.isScam then
			shiftLog.caught += 1
		else
			budget -= Config.FALSE_REJECT_PENALTY
			shiftLog.falseRejections += 1
			shiftLog.falseRejectPenalties += Config.FALSE_REJECT_PENALTY
		end
	elseif decision == "Escalate" then
		shiftMinutes += Config.ESCALATE_TIME_MINUTES
	else
		return
	end

	if not isRescue then
		shiftLog.processed += 1
	end

	tickets[ticketId] = nil
	rejectedTickets[ticketId] = nil
	if decision == "Reject" then
		rejectedTickets[ticketId] = ticket
	end

	if budget <= 0 then
		budget = 0
		endShift()
		return
	end

	broadcastState()
end

local function beginShift(): ()
	if phase ~= "Lobby" then
		return
	end
	tickets = {}
	rejectedTickets = {}
	shiftMinutes = Config.SHIFT_START_MINUTES
	quota = getQuotaForDay(currentDay)
	hasSpawnedScriptedEmailThisShift = false
	shiftLog = {
		processed = 0,
		caught = 0,
		missed = 0,
		falseRejections = 0,
		scamLosses = 0,
		falseRejectPenalties = 0,
	}
	phase = "InShift"
	broadcastState()
end

local function advanceDay(): ()
	if phase ~= "Summary" then
		return
	end
	currentDay += 1
	quota = getQuotaForDay(currentDay)
	phase = "Lobby"
	broadcastState()
end

function TicketSystem.init(): ()
	Workspace:SetAttribute("HelpDeskActiveStage", "BakeryLevel")

	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	gameStateSync = Instance.new("RemoteEvent")
	gameStateSync.Name = "GameStateSync"
	gameStateSync.Parent = remotesFolder

	submitDecision = Instance.new("RemoteEvent")
	submitDecision.Name = "SubmitDecision"
	submitDecision.Parent = remotesFolder

	startShift = Instance.new("RemoteEvent")
	startShift.Name = "StartShift"
	startShift.Parent = remotesFolder

	nextDay = Instance.new("RemoteEvent")
	nextDay.Name = "NextDay"
	nextDay.Parent = remotesFolder

	submitDecision.OnServerEvent:Connect(
		function(player: Player, ticketId: unknown, decision: unknown)
			if typeof(ticketId) ~= "string" then
				return
			end
			if decision ~= "Approve" and decision ~= "Escalate" and decision ~= "Reject" then
				return
			end
			processDecision(player, ticketId, decision :: DecisionType)
		end
	)

	startShift.OnServerEvent:Connect(function(_player: Player)
		beginShift()
	end)

	nextDay.OnServerEvent:Connect(function(_player: Player)
		advanceDay()
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		gameStateSync:FireClient(player, buildGameState())
	end)
end

function TicketSystem.start(): ()
	local lastSpawn = 0
	while true do
		task.wait(1)
		if phase ~= "InShift" then
			continue
		end

		shiftMinutes += Config.GAME_MINUTES_PER_REAL_SECOND
		lastSpawn += 1

		if lastSpawn >= Config.TICKET_SPAWN_INTERVAL_SEC then
			lastSpawn = 0
			local ticket = generateTicket(not hasSpawnedScriptedEmailThisShift)
			hasSpawnedScriptedEmailThisShift = true
			tickets[ticket.id] = ticket
		end

		if shiftMinutes >= Config.SHIFT_END_MINUTES then
			endShift()
		else
			broadcastState()
		end
	end
end

return TicketSystem
