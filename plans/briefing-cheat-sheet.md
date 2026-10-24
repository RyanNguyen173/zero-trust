# Feature Plan: Security Guidelines & Cheat Sheet
Decision: Remove Tells from Tickets / Briefing Guide / Shift Toggle

*Implements Papers, Please style reference handbook per user specification.*

## 1. Goal & Testing
- **Goal:**
  1. Remove "Tells:" spoiler text from tickets. Tickets display only raw data: `Sender`, `Amount`, `Message`.
  2. Briefing screen displays the day's Security Guidelines (rules & red flags to look for).
  3. In-Shift reference: A `[Security Guidelines]` toggle button during the shift allows players to slide open / close the cheat sheet to cross-reference while reviewing tickets.
- **Testing:** Play Solo in Studio.
  - In Briefing: Observe listed red flags (e.g. "Gift Cards: Never allowed", "Look-alike domains: check spelling").
  - Click `[Clock In]`: Verify tickets show ONLY Sender, Amount, and Message (no Tells line).
  - Click `[Security Guidelines]`: Toggles open a reference panel showing the rules.
  - Click again: Closes the reference panel.

## 2. Files to Create / Change
### `src/shared/Types.luau` (Edit)
- In `ClientTicket`: remove `tells: { string }`.
- In `GameState`: ensure `guidelines: { string }` is replicated to clients.

### `src/server/Systems/TicketSystem.luau` (Edit)
- Define `GUIDELINES`: list of active defense rules / tells for the shift.
- In `buildGameState()`: send `guidelines` in payload.
- In `ClientTicket` construction: omit `tells`.

### `src/client/Controllers/TicketDebugUI.luau` (Edit)
- **Briefing View:**
  - Display "Security Guidelines & Red Flags" box listing `state.guidelines`.
- **Shift View:**
  - Remove the "Tells:" string from `buildTicketFrame()`.
  - Add a toggle button `[Security Guidelines]` in the top bar.
  - Add a toggleable side/popup Frame showing the guidelines bullet points for quick checking.

## 3. Remotes
- No remote changes required. `GameStateSync` carries `guidelines: { string }`.

## 4. Existing Code & Instances
- `src/client/Controllers/TicketDebugUI.luau`:
  - Lines 56-65: remove `tells` from `info.Text`.
  - Add guideline toggle frame and button.
- `src/server/Systems/TicketSystem.luau`:
  - Lines 26-51: `TELLS_BY_TYPE` used to supply shift guidelines.

## 5. Out of Scope
- Interactive search or animated book flipping (keep as clean toggleable Frame).
- Multi-app desktop OS window management.
