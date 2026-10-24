# Feature Plan: Fix Ticket Legitimacy & Summary Transparency
Decision: Fix Scam/Legit Desync & Clarify Shift Summary

*Fixes desync in `src/server/Systems/TicketSystem.luau` and summary display.*

## 1. Goal & Testing
- **Goal:**
  1. Fix tell generation: Legitimate tickets (`isScam = false`) must NEVER display scam tells (e.g. "gift card codes", "look-alike domain"). Tells only attach to scams.
  2. Fix summary display: Separate "Scams Slipped Through (-$X)" from "False Rejections (-$Y)" so the player sees exactly why money was lost.
- **Testing:** Play Solo in Studio.
  - Rejecting a ticket with scam tells ALWAYS increments `scamsCaught` and costs $0.
  - Legitimate tickets (clean sender, normal business message, no red flags) approved -> $0 lost.
  - Summary at 5:00 PM clearly shows:
    - Scams Caught: N ($0 lost)
    - Scams Missed: M (-$X lost)
    - False Rejections: K (-$Y lost)
    - Budget Remaining: $Z

## 2. Files to Create / Change
### `src/server/Systems/TicketSystem.luau` (Edit)
- In `generateTicket()`:
  - If `isScam`: sender is spoofed/look-alike, message has urgency/fraud, `tells = pickTells(ticketType)`.
  - If not `isScam`: sender uses verified domain (`@company.com`), message is normal business, `tells = {}` (no scam red flags). Note: Gift card demands are ALWAYS scams (`isScam = true`).
- In `endShift()` / `ShiftLog`:
  - Separate `scamLosses` and `falseRejectPenalties` instead of lumping them into a generic `penalties` counter.

### `src/client/Controllers/TicketDebugUI.luau` (Edit)
- In `SummaryView`:
  - Show separate line items:
    - "Scams Blocked: X"
    - "Scams Slipped Through: Y (-$A)"
    - "Legit Tickets Rejected: Z (-$B)"
    - "Budget Remaining: $C"

## 3. Remotes
- No remote changes required. `lastSummary` in `GameStateSync` carries the split `scamLosses` and `falseRejectPenalties`.

## 4. Existing Code & Instances
- `src/server/Systems/TicketSystem.luau` lines 127-149: `generateTicket()` attaches tells before checking `isScam`.
- `src/client/Controllers/TicketDebugUI.luau` lines 110-140: summary text labels.

## 5. Out of Scope
- Visual design polish or 3D office models.
