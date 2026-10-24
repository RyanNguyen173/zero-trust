# Plan: Multiplayer Co-Op System

## 1. Goal + Studio Test
Support 1-4 players working together in the same office: multiple desk workstations, shared company budget, ticket claiming/dispatch, and coworker ticket escalation ("Ask Second Opinion").
**Test**: In 2-player Studio local server, Player 1 and Player 2 sit at separate desks. Player 1 forwards a ticket to Player 2; Player 2 receives prompt and approves/rejects it. Shared budget updates on both screens.

## 2. Files to Create / Change
- `src/server/Systems/DeskManager.luau` (new):
  - Clones `ITWorkstation` in `BakeryLevel` to positions 1-4.
  - `claimDesk(player, deskId)`: Binds player to desk, unbinds on stand/leave.
- `src/server/Systems/TicketSystem.luau`:
  - `tickets`: Keyed by ID, stores `claimedBy: Player?` and `history: { { player: Player, action: string } }`.
  - `assignTicket(player, ticketId)`: Locks ticket to claiming player.
  - `forwardTicket(fromPlayer, toPlayer, ticketId)`: Reassigns ticket with notification.
  - Broadcasts individual inbox state (`assignedTickets`) + shared pool (`unassignedTickets`).
- `src/client/Controllers/DesktopUI.luau`:
  - Adds `[Forward to Coworker]` button in RoMail window.
  - Shows teammate presence tray icons (who is online/at desk).
  - High-risk alert banner: *"@Teammate is reviewing a $5,000 wire!"*
- `src/client/Controllers/OfficeBoardController.luau` (new):
  - Updates 3D SurfaceGui in Briefing Room: Team Quota, Live Budget, MVP Defender.

## 3. Remotes (`src/shared/Remotes.luau`)
- `ClaimDesk` (Client -> Server): `(deskId: string)`
- `ForwardTicket` (Client -> Server): `(ticketId: string, targetPlayer: Player)`
- `TicketForwarded` (Server -> Client): `(ticket: ClientTicket, fromPlayerName: string)`
- `DeskStateSync` (Server -> Client): `({ [string]: { occupiedBy: string?, deskName: string } })`

## 4. Existing Code to Know
- `src/server/Systems/TicketSystem.luau`: Currently uses global single `tickets` table and broadcasts identical state to all players.
- `src/client/Controllers/DesktopUI.luau`: Lines 1395-1415 for `ITWorkstation.ITScreen.ComputerPrompt` interaction.

## 5. Out of Scope
- Voice chat integrations (Roblox spatial voice is automatic).
- Physical sabotage/throwing props (keep focused on defense co-op).
