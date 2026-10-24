# Feature Plan: 150-Email Story Database
Decision: 150 Curated Emails / 60 Legit & 90 Scams / 5 Tiers

*Implements complete 150-email scenario database across all 5 company levels.*

## 1. Goal & Testing
- **Goal:** Place `src/shared/EmailDatabase.luau` containing 150 fully written, realistic emails (30 per company tier: 12 legit, 18 scams = 60 legit, 90 scams total) based on the full 25-shift specification:
  - *Tier 1: Crumb & Crust Bakery* (Pastry chef gift cards, dairy phishing, flour mill routing, wedding cake .pdf.exe, Marco espresso wire + routine bakery invoices).
  - *Tier 2: Apex Indie Game Studio* (Steam cert phishing, 3D rig .blend.exe, sound designer invoice, remote build tool, publisher NDA escrow + routine asset/sound invoices).
  - *Tier 3: Pulse Logistics* (Cyrillic homoglyph pilotfleets, diesel fuel math forgery, customs container wire, dispatch terminal network spike, route .xlsm macros + routine freight bills).
  - *Tier 4: OmniHealth BioPharma* (Trial OAuth permissions, ultrasound machine fake helpline, stipends .zip.js, lateral lab scan, CMO patent wire + routine lab supply POs).
  - *Tier 5: Federal Aerospace Depot* (Reverse-proxy token refresh, titanium alloy offshore escrow, General Vance wire, telemetry ransomware note + routine defense logistics contracts).
- **Testing:** Play Solo in Studio.
  - Advance through days; observe RoMail pulling realistic, narrative-driven emails with authentic sender names, realistic corporate prose, believable amounts, and documented tells.
  - 60 legitimate emails match Directory records and contain zero scam tells.

## 2. Files to Create / Change
### `src/shared/EmailDatabase.luau` (Create)
- Pre-generated full dataset ready at:
  `C:\Users\ryant\.gemini\antigravity-cli\brain\29866a8b-b6af-42c1-9462-942b7f5f174b\scratch\EmailDatabase.luau`
  (Copy this complete 150-record Luau module directly into `src/shared/EmailDatabase.luau`).
- Functions provided: `getAll()`, `getByTier(tier)`, `getShiftScenario(shift)`, `getRandomByTier(tier, isScam)`.

### `src/server/Systems/TicketSystem.luau` (Edit)
- Require `Shared.EmailDatabase`.
- In `generateTicket()`: pull the scripted scenario email for today's shift via `EmailDatabase.getShiftScenario(currentShift)` on first ticket, and sample from `EmailDatabase.getRandomByTier(tier)` for subsequent tickets.

## 3. Remotes
- Reuses `GameStateSync`, `SubmitDecision`, `StartShift`, `NextDay`.

## 4. Existing Code & Instances
- `src/server/Systems/TicketSystem.luau`: ticket spawning loop.
- `src/client/Controllers/DesktopUI.luau`: email reading pane.

## 5. Out of Scope
- Interactive sandbox engines (Engine A/C/D mini-windows; emails display attachment names and text for triage via Approve/Reject).
