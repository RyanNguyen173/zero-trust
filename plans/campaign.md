# Feature Plan: Company Tiers & 5-Day Campaign
Decision: Tier Selection / Break Room Quota / Progressive Unlocks

*Implements `docs/zero-trust.md` §§1 & 2 (Company levels, 5-day week, break room quota).*

## 1. Goal & Testing
- **Goal:** Players pick an unlocked company in the lobby, committing to a 5-day week (Mon–Fri). Each day starts in the Break Room with a Daily Quota (e.g. process min X tickets, catch min Y scams). Decisions give NO immediate feedback during shift; consequences and quota success/failure are revealed in the Break Room at 5:00 PM.
- **5 Tiers:**
  1. *Local Business* ($15k budget, low quota, obvious tells) — Unlocked.
  2. *Small Business* ($30k budget, medium quota) — Unlocks after Tier 1.
  3. *Medium Business* ($60k budget, high quota) — Unlocks after Tier 2.
  4. *Large Corporation* ($150k budget, strict quota, complex tells) — Unlocks after Tier 3.
  5. *Government Agency* ($500k budget, high velocity, deceptive) — Unlocks after Tier 4.
- **Testing:** Play Solo in Studio.
  - Break room UI shows day quota (e.g. "Quota: 6 tickets processed, 2 scams caught").
  - Click "Start Shift" -> runs 9:00 AM – 5:00 PM shift. Decisions provide no immediate feedback.
  - At 5:00 PM, returns to Break Room summary: shows quota met/missed, scams caught, money lost, updated budget.
  - Hitting quota advances day (Mon -> Tue -> ... -> Fri). Completing Fri unlocks next tier. Missing quota or hitting $0 budget fails the week.

## 2. Files to Create / Change
### `src/shared/Types.luau` (Edit)
- Add types:
  - `export type DailyQuota = { minProcessed: number, minScamsCaught: number }`
  - `export type CompanyTier = { id: number, name: string, startBudget: number, ticketInterval: number, quotas: { [number]: DailyQuota }, description: string }`
  - `export type CampaignState = { unlockedTier: number, selectedTier: number?, currentDay: number, dayStatus: "BreakRoomBriefing" | "InShift" | "BreakRoomSummary" | "GameOver" | "WeekComplete", currentQuota: DailyQuota?, lastShiftLog: ShiftLog?, currentBudget: number }`

### `src/shared/Config.luau` (Edit)
- Add `COMPANY_TIERS` table with 5 tiers, initial budgets, ticket spawn rates, and 5 daily quotas for each tier.

### `src/server/Systems/CampaignManager.luau` (Create)
- State: `unlockedTier = 1`, `selectedTier = 1`, `currentDay = 1`, `dayStatus = "BreakRoomBriefing"`, `budget: number`.
- Functions:
  - `selectCompany(player: Player, tierId: number)`: sets tier, day 1, loads tier starting budget and day 1 quota, status = `"BreakRoomBriefing"`.
  - `startShift(player: Player)`: transitions from `"BreakRoomBriefing"` to `"InShift"`, starts `TicketSystem`.
  - `onShiftComplete(shiftLog: ShiftLog)`: evaluates quota (`shiftLog.ticketsProcessed >= quota.minProcessed` and `shiftLog.scamsCaught >= quota.minScamsCaught`).
    - If failed quota or `budget <= 0`: status = `"GameOver"`.
    - If passed and `currentDay < 5`: `currentDay += 1`, status = `"BreakRoomSummary"`.
    - If passed Day 5: `unlockedTier = math.max(unlockedTier, selectedTier + 1)`, status = `"WeekComplete"`.
  - `syncState()`: replicates `CampaignState` to clients.

### `src/client/Controllers/BreakRoomUI.luau` (Create)
- Renders placeholder UI panels:
  - Lobby/Tier Select: Pick unlocked company (Tiers 1–5).
  - Break Room Briefing: Displays Company name, Day (Mon–Fri), Current Budget, and Daily Quota + "[Start Shift]" button.
  - Break Room Summary: Shows 5:00 PM results (Quota Met/Missed, Scams Caught, Budget Remaining) + "[Next Day]" button.

## 3. Remotes
Parented under `ReplicatedStorage/Remotes/`:
- `CampaignSync` (`RemoteEvent`, Server -> Client): payload `(state: CampaignState)`.
- `SelectCompany` (`RemoteEvent`, Client -> Server): payload `(tierId: number)`.
- `StartShift` (`RemoteEvent`, Client -> Server): begins the shift from Break Room.

## 4. Existing Code & Instances
- `src/server/Systems/TicketSystem.luau`: runs shift loop, silently tracks `ShiftLog`, signals `onShiftComplete`.
- `src/shared/Types.luau` & `Config.luau`: shared contracts.

## 5. Out of Scope
- 3D physical office navigation (placeholder UI buttons used for briefing/summary transition).
- DataStore persistence across server shutdowns.
