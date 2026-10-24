--!strict
-- Shared type definitions. Types that cross the client/server boundary
-- (remote payloads, profile schema) live here so both sides agree.

export type PlayerProfile = {
	version: number,
	coins: number,
}

-- Widened to string: the 150-email story database (EmailDatabase.luau) spans ~27 distinct
-- ticket type labels across its 5 company tiers, too many to enumerate as a union.
export type TicketType = string

export type DecisionType = "Approve" | "Escalate" | "Reject"

export type Ticket = {
	id: string,
	ticketType: TicketType,
	sender: string,
	message: string,
	amount: number?,
	tells: { string },
	isScam: boolean,
}

export type ClientTicket = {
	id: string,
	ticketType: TicketType,
	sender: string,
	message: string,
	amount: number?,
}

export type Phase = "Lobby" | "InShift" | "Summary" | "GameOver"

export type Quota = {
	minProcessed: number,
	minScams: number,
}

export type ShiftSummary = {
	processed: number,
	caught: number,
	missed: number,
	falseRejections: number,
	scamLosses: number,
	falseRejectPenalties: number,
	budgetLeft: number,
	quotaPassed: boolean,
}

export type GameState = {
	phase: Phase,
	day: number,
	tierName: string,
	shiftMinutes: number,
	tickets: { ClientTicket },
	quota: Quota,
	lastSummary: ShiftSummary?,
	guidelines: { string },
}

return nil
