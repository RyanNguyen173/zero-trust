# Feature Plan: Bakery Workstation & Desktop UI Refinements
Decision: 3D Terminal Interaction / Log Off / Trash Bin / 2-Button Decisions

*Implements workstation immersion and UI updates per user specification.*

## 1. Goal & Testing
- **Goal:**
  1. *3D Workstation Entry/Exit:* `DesktopUI` starts hidden (`Enabled = false`). Interacting with `Workspace.BakeryLevel.ITWorkstation.ITScreen.ComputerPrompt` opens the desktop. Taskbar Start ("Log Off") button or `Esc` key closes the desktop and returns to the 3D character.
  2. *Two-Button Triage:* Remove `[Escalate]`. Keep ONLY **`[Approve]`** and **`[Reject]`**.
  3. *Trash Folder:* Remove `Spam`. When a ticket is rejected, move it to `Trash` with a red "[REJECTED]" tag. Selecting a rejected ticket in Trash displays it and allows the player to click `[Approve]` if they made a mistake.
  4. *Desktop Icons:* Delete `Blox Bin`. Clicking `RoNotes` desktop icon toggles the yellow sticky note open/closed.
  5. *Level Setup:* Set `workspace:SetAttribute("HelpDeskActiveStage", "BakeryLevel")` on server start so player spawns at `BakeryLevel.Arrival.Spawn`.
- **Testing:** Play Solo in Studio.
  - Player spawns in the Bakery. Walk up to IT Workstation desk, trigger prompt -> BloxOS desktop opens.
  - RoMail shows Inbox and Trash. Rejecting an email moves it to Trash with a red badge. Open Trash, click it, and verify you can rescue it with `[Approve]`.
  - Click taskbar "Log Off" button -> desktop closes, player is back in the 3D bakery.

## 2. Files to Create / Change
### `src/client/Controllers/DesktopUI.luau` (Edit)
- **Workstation Open/Close:**
  - `screenGui.Enabled = false` initially.
  - Connect to `Workspace.BakeryLevel.ITWorkstation.ITScreen.ComputerPrompt.Triggered`: opens desktop (`screenGui.Enabled = true`).
  - Start button: rename text/tooltip to "Log Off", click handler closes desktop (`screenGui.Enabled = false`).
  - Keybind `Enum.KeyCode.Escape`: closes desktop.
- **Two Buttons:** Remove `makeChunkyButton` for `[Escalate]`. Keep only `[Approve]` and `[Reject]`.
- **Trash Folder Logic:**
  - Track `rejectedTickets: { [string]: ClientTicket }`.
  - Folder pane shows `Inbox` and `Trash` (remove `Spam`).
  - Clicking `[Reject]` adds ticket to `rejectedTickets` and sends `SubmitDecision(id, "Reject")`.
  - Clicking `Trash` renders list of rejected tickets with red badge; reading pane allows `[Approve]`.
- **Desktop Icons:** Remove `Blox Bin`. Clicking `RoNotes` toggles `roNotes.Visible`.

### `src/server/Systems/TicketSystem.luau` (Edit)
- Set `workspace:SetAttribute("HelpDeskActiveStage", "BakeryLevel")` on server init.
- Handle rescued tickets from Trash (if player Approves a previously rejected ticket).

## 3. Remotes
- Reuses existing `SubmitDecision`, `GameStateSync`, `StartShift`, `NextDay`.

## 4. Existing Code & Instances
- `Workspace.BakeryLevel.ITWorkstation.ITScreen.ComputerPrompt`: existing ProximityPrompt in Workspace.
- `Workspace.BakeryLevel.Arrival.Spawn`: spawn location.

## 5. Out of Scope
- Camera zoom animation (instant toggle is robust and snappy).
