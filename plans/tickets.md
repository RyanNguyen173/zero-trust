# Feature Plan: Core Ticket System
Decision: Approve / Send to Higher Up / Reject

*Implements `docs/zero-trust.md` §§1, 2, 4, 5 & `docs/scam-game.md` §Core Loop.*

## 1. Goal & Testing
- **Goal:** Server runs a 9:00 AM – 5:00 PM shift clock (1 real min = 1 game hr = 480s total) and tracks Company Budget ($50,000 start; $0 = team fired). Server spawns tickets across 4 scam/legit types with 1–3 tells. Client displays a plain debug panel with clock, ticket list, and 3 buttons.
- **Hidden Outcome Rule:** Player receives NO instant feedback on decisions (no win/loss indicator, no instant budget counter updates per click). Outcomes are logged server-side and revealed only at shift end (or sudden bankruptcy at $0).
- **Testing:** Play Solo in Studio. Verify shift clock advances from 9:00 AM.
  - Making decisions (Approve, Escalate, Reject) removes the ticket from UI without showing whether it was correct or wrong.
  - Escalate adds 10 game-minutes (10s) to the shift clock.
  - Server silently logs scams missed, legit rejected, and safe escalations.
  - Server terminates run if secret budget reaches $0.

## 2. Files to Create / Change
### `src/shared/Types.luau` (Edit)
- Add types:
  - `export type TicketType = "FakeCEO" | "VendorBankChange" | "GiftCardDemand" | "PhishingLink"`
  - `export type DecisionType = "Approve" | "Escalate" | "Reject"`
  - `export type Ticket = { id: string, ticketType: TicketType, sender: string, message: string, amount: number, tells: { string }, isScam: boolean }`
  - `export type ClientTicket = { id: string, ticketType: TicketType, sender: string, message: string, amount: number, tells: { string } }` (omits `isScam`)
  - `export type ShiftLog = { ticketsProcessed: number, scamsCaught: number, scamsMissed: number, legitRejected: number, moneyLost: number }`
  - `export type GameState = { shiftMinutes: number, isGameOver: boolean, tickets: { ClientTicket } }`

### `src/shared/Config.luau` (Edit)
- Add configuration:
  - `START_BUDGET = 50_000`, `FALSE_REJECT_PENALTY = 500`, `ESCALATE_TIME_MINUTES = 10`
  - `SHIFT_START_MINUTES = 9 * 60` (540), `SHIFT_END_MINUTES = 17 * 60` (1020)
  - `GAME_MINUTES_PER_REAL_SECOND = 1`, `TICKET_SPAWN_INTERVAL_SEC = 10`

### `src/server/Systems/TicketSystem.luau` (Create)
- Module with `init()` and `start()`. Server-authoritative state.
- State: `budget: number`, `shiftMinutes: number`, `tickets: { [string]: Ticket }`, `log: ShiftLog`, `isGameOver: boolean`.
- Functions:
  - `generateTicket(): Ticket`: selects type, randomizes scam (60%) vs legit (40%), generates realistic sender, message, amount ($500-$40,000), and 1-3 tells from `docs/scam-game.md`.
  - `processDecision(player: Player, ticketId: string, decision: DecisionType)`:
    - Validates ticket exists; updates `log.ticketsProcessed += 1`.
    - If `Approve`: if `isScam` then `budget -= ticket.amount`, `log.scamsMissed += 1`, `log.moneyLost += ticket.amount`.
    - If `Reject`: if `isScam` then `log.scamsCaught += 1` else `budget -= Config.FALSE_REJECT_PENALTY`, `log.legitRejected += 1`, `log.moneyLost += Config.FALSE_REJECT_PENALTY`.
    - If `Escalate`: `shiftMinutes += Config.ESCALATE_TIME_MINUTES` (safe resolution, no budget loss).
    - Removes ticket from queue and syncs active tickets to clients (without outcome verdict).
    - Checks if `budget <= 0` (fires game over) or `shiftMinutes >= SHIFT_END_MINUTES`.
  - `start()`: spawns game loop timer (advances `shiftMinutes` each second, spawns tickets, syncs).

### `src/client/Controllers/TicketDebugUI.luau` (Create)
- Module with `init()` and `start()`.
- Creates a ScreenGui debug panel: Shift Clock (`09:00 AM`), ScrollingFrame of active tickets.
- Each ticket displays ID, Type, Sender, Amount, Message, Tells, and 3 plain TextButtons: `[Approve]`, `[Send to Higher Up]`, `[Reject]`.
- Button clicks fire `SubmitDecision` RemoteEvent with `(ticketId, decision)` and immediately clear that ticket from local display.

## 3. Remotes
Parented under `ReplicatedStorage/Remotes/`:
- `GameStateSync` (`RemoteEvent`, Server -> Client): payload `(state: GameState)`.
- `SubmitDecision` (`RemoteEvent`, Client -> Server): payload `(ticketId: string, decision: DecisionType)`.
  - Server validation: `ticketId` must match active server ticket; `decision` must be `"Approve"`, `"Escalate"`, or `"Reject"`.

## 4. Existing Code & Instances
- `src/server/init.server.luau` (lines 5-26): autoloads `Systems/`.
- `src/client/init.client.luau` (lines 4-25): autoloads `Controllers/`.
- `src/shared/Types.luau` & `Config.luau`: define contracts and constants.

## 5. Out of Scope
- Immediate feedback UI pop-ups (explicitly disallowed by game design).
- Audio alarms, 3D office workstation seats.
