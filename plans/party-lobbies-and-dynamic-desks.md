# Plan: Party Lobbies & Dynamic Multi-Desk Scaling

## 1. Goal + Studio Test
Enable players to form party lobbies in the main hub, travel together to a company level, pick an available desk (level capacity = desk count), and triage a shared ticket/call queue dynamically scaled to player count.
**Test**: In a 2-player Studio test, Party Host selects Bakery (2 desks). Both players sit at separate desks. Tickets spawn at 1.75x rate. When Player 1 rejects an email, Player 2's screen immediately shows it resolved.

## 2. Files to Create / Change
- `src/server/Systems/LobbyManager.luau` (new):
  - `createParty(host: Player)`: Creates party with join code / invite.
  - `joinParty(player: Player, partyId: string)`: Adds player up to level desk capacity.
  - `startLevel(partyId: string, levelName: string)`: Teleports party members to level spawn and initializes shift.
- `src/server/Systems/DeskManager.luau` (new):
  - Scans level model for workstations (`ITWorkstation`, `Workstation_1`, etc.).
  - Tracks desk occupancy (`claimedBy: Player?`).
  - Sets overhead BillboardGui (`Available` / `Occupied by <Name>`).
- `src/server/Systems/TicketSystem.luau`:
  - `getSpawnInterval(playerCount: number)`: Dynamically scales ticket spawn rate: `Config.TICKET_INTERVAL / (1 + (playerCount - 1) * 0.75)`.
  - Syncs ticket actions in real time: when one player resolves/stamps a ticket, it broadcasts `TicketResolved(ticketId, player, action)` to all party members.
- `src/client/Controllers/LobbyUI.luau` (new):
  - Party lobby creation & invite UI in main hub.
  - Level selection showing player capacity: `Bakery (1-2 Players)`, `Game Studio (1-3 Players)`, etc.
- `src/client/Controllers/DesktopUI.luau`:
  - Binds prompt to whichever desk the player is sitting at.
  - Shows teammate live status banner: *"@Teammate approved Invoice #104 (+1)"*.

## 3. Remotes (`src/shared/Remotes.luau`)
- `PartyAction` (Client -> Server): `(action: "create" | "join" | "leave" | "start", payload: any)`
- `PartyStateSync` (Server -> Client): `(partyData: Types.PartyData)`
- `ClaimDesk` (Client -> Server): `(deskId: string)`
- `TicketResolvedSync` (Server -> Client): `(ticketId: string, resolverName: string, action: string)`

## 4. Existing Code to Know
- `src/server/Systems/TicketSystem.luau`: `tickets` loop and `broadcastState()`.
- `Workspace.GameCompanyLevel`: Already contains `Workstation_1`, `Workstation_2`, `Workstation_3`.
- `Workspace.BakeryLevel`: Currently contains 1 `ITWorkstation`; builder can clone for 2nd desk.

## 5. Out of Scope
- Matchmaking queues (direct friend invite / party code is sufficient).
- Cross-server teleporting (parties play in the current server instance).
