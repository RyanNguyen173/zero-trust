# Feature Plan: Playable Game Flow Prototype
Decision: Lobby & Briefing -> 9-to-5 Shift (Hidden Feedback) -> 5 PM Review

*Implements `docs/zero-trust.md` §§1, 2, 5 & user specifications for playtesting.*

## 1. Goal & Testing
- **Goal:** Connect `TicketSystem` into a complete, testable 3-phase game loop:
  1. *Lobby & Threat Briefing*: View Company, Day (Mon–Fri), Daily Quota (e.g. Process 5, Catch 2 scams), and **Threat Intel / Red Flags to Watch For** (e.g. gift card demands, typosquatted domains), click `[Clock In]`.
  2. *The Shift (9:00 AM - 5:00 PM)*: Tickets arrive. Submit decisions (`Approve`, `Higher Up`, `Reject`). NO instant feedback or live budget drops shown.
  3. *5:00 PM Summary*: Review quota (Met/Missed), scams caught/missed, budget deducted, and advance to Day 2 or game over.
  - *Rapid Testing Speed:* Configurable 60-90s test shift (`GAME_MINUTES_PER_REAL_SECOND = 6`, so 80 real seconds = 8 game hours).
- **Testing:** Play Solo in Studio.
  - Screen displays Lobby/Briefing with Day 1 Quota and Threat Intel tips ("Red Flags: No legitimate company demands gift cards; watch for external reply-to addresses"). Click `[Clock In]`.
  - Shift UI appears, clock counts 9:00 AM -> 5:00 PM. Decide on tickets (disappear cleanly with no feedback).
  - At 5:00 PM, Shift Summary pops up showing report card and quota verdict. Click `[Next Day]` to advance to Tuesday briefing.

## 2. Files to Create / Change
### `src/shared/Types.luau` (Edit)
- Add `Phase = "Lobby" | "InShift" | "Summary" | "GameOver"`
- Update `GameState`: `{ phase: Phase, day: number, tierName: string, shiftMinutes: number, tickets: { ClientTicket }, quota: { minProcessed: number, minScams: number }, threatBriefing: { string }, lastSummary: { processed: number, caught: number, missed: number, penalties: number, budgetLeft: number, quotaPassed: boolean }? }`

### `src/shared/Config.luau` (Edit)
- Set `GAME_MINUTES_PER_REAL_SECOND = 6` (80s shift) and `TICKET_SPAWN_INTERVAL_SEC = 6`.
- Add `DAY_CONFIGS`: Day 1-5 definitions with quotas, starting budget ($25k), and `threatBriefing` strings:
  - Day 1: "Gift Card Scams: No vendor or exec ever asks for gift cards. Reject immediately."
  - Day 2: "Domain Typosquatting: Inspect sender email closely (`cornpany.com` vs `company.com`)."
  - Day 3: "Vendor Bank Routing: Unannounced bank changes must be escalated or verified."
  - Day 4: "Phishing Links: Mismatched link text or urgent account suspension threats."
  - Day 5: "Mixed High-Velocity Attacks: Multiple concurrent social engineering vectors."

### `src/server/Systems/TicketSystem.luau` (Edit)
- Lifecycle: `phase: Phase`, `currentDay: number`, `quota`, `threatBriefing`, `shiftLog`.
- `processDecision()`: stop broadcasting updated budget on every click; record to hidden `shiftLog`.
- `start()`: don't auto-run shift on boot; wait for `StartShift` remote from client.
- When `shiftMinutes >= 17 * 60`: set `phase = "Summary"`, calculate quota pass/fail, apply accumulated budget losses, broadcast summary.

### `src/client/Controllers/TicketDebugUI.luau` (Edit)
- 3-view controller based on `state.phase`:
  - `BriefingView`: Shows Company ("Local Business"), Day ("Monday - Day 1"), Quota ("Process 5, Catch 2"), **Threat Briefing Box** (list of red flags to watch for), and `[Clock In / Start Shift]` button.
  - `ShiftView`: Ticket list + 3 decision buttons + Clock (`09:00 AM`). Live budget is hidden.
  - `SummaryView`: Displays shift results: Quota Met/Missed, Scams Caught, Money Lost, Budget Remaining. `[Next Day]` button.

## 3. Remotes
In `ReplicatedStorage/Remotes/`:
- `GameStateSync` (`RemoteEvent`, Server -> Client): sends updated `GameState`.
- `SubmitDecision` (`RemoteEvent`, Client -> Server): `(ticketId: string, decision: DecisionType)`.
- `StartShift` (`RemoteEvent`, Client -> Server): triggered by `[Clock In]` button.
- `NextDay` (`RemoteEvent`, Client -> Server): triggered from Summary to start next briefing.

## 4. Existing Code & Instances
- `src/server/Systems/TicketSystem.luau` (lines 169-247): ticket generation and decision handling.
- `src/client/Controllers/TicketDebugUI.luau` (lines 39-85): ticket frame rendering.

## 5. Out of Scope
- Final 3D office environment & walking navigation (focus on core loop feel and fun).
- Dual approval & audio effects.
