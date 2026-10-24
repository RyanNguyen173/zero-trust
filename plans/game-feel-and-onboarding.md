# Plan: Game Feel & Day 1 Onboarding (Dopamine & Accessibility)

## 1. Goal + Studio Test
Make the game instantly addictive (tactile stamp slam, streak combo counter, sound pitch escalation) while making Day 1 foolproof (guided spotlight on first ticket tell, 1-click Directory link).
**Test**: Start Bakery Day 1. Ticket 1 highlights tell with tutorial bubble. Clicking Reject plays loud Stamp Slam animation, confetti, and increments Combo x1 with high-pitch chime.

## 2. Files to Create / Change
- `src/client/Controllers/DesktopUI.luau`:
  - `playStampEffect(action: "approve" | "reject")`: Spawns angled stencil stamp (`VERIFIED` green / `REJECTED` red) scaled from 1.6x down to 1.0x with `Back` out easing, 4px camera shake, and Sound trigger.
  - `updateCombo(streak: number)`: Pops `COMBO x<N> 🔥` pill with spring bounce at top of RoMail window.
  - `showTutorialSpotlight(targetFrame: GuiObject, tipText: string)`: Semi-transparent backdrop highlighting tell text with mascot hint bubble on Shift 1 Ticket 1 only.
  - `renderTicket(ticket)`: Adds inline clickable `[@Name]` tag that opens Directory and filters directly to that person.
- `src/client/Controllers/AudioController.luau` (new):
  - Sound instances for Stamp Slam (`rbxassetid://6026978438`), Combo Ding with ascending pitch (`PlaybackSpeed = 1.0 + (streak * 0.08)`), and Confetti Chime.
- `src/server/Systems/TicketSystem.luau`:
  - `evaluateTicket(player, ticketId, action)`: Tracks per-shift player streak (`currentStreak`). Sends `StreakUpdated` remote to client. Streak resets on wrong call.

## 3. Remotes (`src/shared/Remotes.luau`)
- `StreakUpdated` (Server -> Client): `(streak: number, bonus: number)`
- `TutorialCompleted` (Client -> Server): `(stepId: string)`

## 4. Existing Code to Know
- `src/client/Controllers/DesktopUI.luau`: Decision buttons in `createRoMailWindow()` (`approveBtn.MouseButton1Click`, `rejectBtn.MouseButton1Click`).
- `src/server/Systems/TicketSystem.luau`: Triage decision handler where budget/saved amounts are calculated.
- `src/shared/Config.luau`: Add `COMBO_STREAK_BONUS = 50`.

## 5. Out of Scope
- Desk 3D pets/gacha crates (keep for 5 PM review upgrade store).
- Timed pressure events (Day 1-2 are untimed).
