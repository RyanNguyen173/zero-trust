# Feature Plan: Crumb & Crust Bakery Scenarios (Week 1)
Decision: 5-Day Bakery Shift Content / Specific Scams & Tells / Directory

*Implements Level 1: Crumb & Crust Bakery (Tier 1: Local Business) from specification.*

## 1. Goal & Testing
- **Goal:** Replace placeholder ticket generation with the exact 5-day Crumb & Crust Bakery campaign:
  - **Day 1 (Mon):** *The Butter Supply Run (Gift Card Demand)* — Chef Pierre ($200 Vanilla Visa cards for butter). Tell: fake callback `555-0144` vs Directory verified Ext. 102 (`555-0102`). Rule: suppliers use trade credit, never gift cards.
  - **Day 2 (Tue):** *The Egg Delivery Portal (Phishing Link)* — Happy Valley Dairy egg delivery suspended. Tell: `free-egg-orders.biz` vs Directory verified `happyvalleydairy.com` (`555-0199`).
  - **Day 3 (Wed):** *Flour Mill Routing Audit (Vendor Bank Change)* — Golden Grain Mills 30 bags flour. Tell: `ACCT-8899-FAKE` / `555-9988` vs Directory verified `ACCT-1022-REAL` / `555-0177`.
  - **Day 4 (Thu):** *Catering Order Scanner (Suspect Attachment)* — Wedding cake custom specs `Wedding_Cake_Custom_Specs.pdf.exe`. Tell: `.pdf.exe` double extension & `555-BRIDE` vs Directory client `555-0133`.
  - **Day 5 (Fri):** *The Espresso Machine Deal (Fake CEO Wire)* — Head Baker Marco urgent $800 transfer for auction machine. Tell: secrecy + burner cell `555-0111` vs Directory intercom Ext. 12.
  - Plus legitimate bakery tickets mixed in every shift (routine deliveries, standard invoices per contract).
- **Testing:** Play Solo in Studio.
  - Day 1: Ticket from Chef Pierre asking for $200 gift cards arrives. Check Directory (Pierre Ext. 102 / 555-0102). Click `[Reject]` -> scam caught.
  - Advance through Days 2 to 5 verifying each scenario against Directory records.

## 2. Files to Create / Change
### `src/shared/Config.luau` (Edit)
- Update `COMPANY_DIRECTORY`:
  - `staff = { { name = "Chef Pierre", title = "Head Pastry Chef", email = "pierre@crumbcrust.com", phone = "555-0102 (Ext. 102)" }, { name = "Marco Rossi", title = "Head Baker / Owner", email = "marco@crumbcrust.com", phone = "Ext. 12 (Kitchen Intercom)" } }`
  - `vendors = { { name = "Happy Valley Dairy", email = "orders@happyvalleydairy.com", routing = "happyvalleydairy.com", account = "555-0199" }, { name = "Golden Grain Mills", email = "billing@goldengrain.com", routing = "021000021", account = "ACCT-1022-REAL (Phone: 555-0177)" }, { name = "Sarah's Wedding Catering", email = "sarah@cateringclient.com", routing = "Catering Client", account = "Phone: 555-0133" } }`
- Define `BAKERY_SHIFTS`: table indexing Days 1–5 with scenario descriptions, scam email templates, tells, and legit templates.

### `src/server/Systems/TicketSystem.luau` (Edit)
- Update `generateTicket()`: pull daily campaign scenarios from `BAKERY_SHIFTS` for `currentDay`.
- Mix in legitimate bakery supplier invoices matching the Directory entries.

## 3. Remotes
- Reuses existing `GameStateSync`, `SubmitDecision`, `StartShift`, `NextDay`.

## 4. Existing Code & Instances
- `src/server/Systems/TicketSystem.luau`: ticket generator and day state.
- `src/shared/Config.luau`: directory and constants.

## 5. Out of Scope
- Interactive mini-game engines (URL slicer block-clicker, VM sandbox drag) — for this pass, investigate via email text vs Directory, and resolve with `[Approve]` / `[Reject]`.
