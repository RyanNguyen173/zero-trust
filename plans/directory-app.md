# Feature Plan: Company Directory App
Decision: Investigative Cross-Reference Tool / Staff & Vendor Registry

*Implements `docs/zero-trust.md` §3 (Directory App) & §4 (Verification Counters).*

## 1. Goal & Testing
- **Goal:** Add a second usable BloxOS desktop app: **Company Directory**.
  - Players open it to cross-reference incoming ticket senders, domains, and banking info against verified company records to spot typosquats (e.g. `cornpany.com` vs `company.com`, `acrne-supplies` vs `acme-supplies`).
  - Features two tabs: **Employees** (Name, Title, Official Email, Phone) and **Approved Vendors** (Vendor Name, Official Billing Email, Verified Bank Account/Routing).
- **Testing:** Play Solo in Studio.
  - Desktop shows "Directory" shortcut icon on the left.
  - Clicking "Directory" opens a BloxOS window styled like RoMail (titlebar with vector `_` `□` `✕`, dark panels).
  - Switching between "Employees" and "Vendors" tabs displays verified contacts.
  - Compare incoming RoMail sender `accounts@acrne-supplies.com` with Directory entry (`billing@acme-supplies.com`) to confirm scam tell.

## 2. Files to Create / Change
### `src/shared/Config.luau` (Edit)
- Add `COMPANY_DIRECTORY`:
  - `staff = { { name = "John Harrington", title = "CEO", email = "ceo@company.com", phone = "Ext. 101" }, { name = "Alex Chen", title = "IT Lead", email = "it-support@company.com", phone = "Ext. 112" }, { name = "Sarah Jenkins", title = "CFO", email = "s.jenkins@company.com", phone = "Ext. 104" } }`
  - `vendors = { { name = "Acme Supplies Co.", email = "billing@acme-supplies.com", routing = "021000021", account = "****-4920" }, { name = "Global Parts Corp.", email = "ap@globalparts.co", routing = "122000496", account = "****-8812" } }`

### `src/client/Controllers/DesktopUI.luau` (Edit)
- Replace placeholder `BloxBank` desktop icon with `Directory` (address book vector icon: blue book with small white person/lines).
- Add `buildDirectoryWindow()`:
  - Size: `UDim2.new(0.5, 0, 0.7, 0)`, centered or docked.
  - Titlebar: "Company Directory - Verified Contacts", close/minimize buttons.
  - Tab header: `[Employees]` and `[Approved Vendors]` buttons (active tab highlighted).
  - Content pane: ScrollingFrame rendering contact cards with Name, Title/Category, and verified Email/Bank in green-tinted monospaced font.
- Wire icon click & window toggling (`directoryOpen = not directoryOpen`).

## 3. Remotes
- None. Directory is reference data replicated via `Shared/Config.luau`.

## 4. Existing Code & Instances
- `src/client/Controllers/DesktopUI.luau`:
  - Lines 700-750: `buildDesktopIcons` icon list and click handlers.
  - Lines 604-670: `buildMailWindow` window structure (pattern to replicate for Directory window).
- `src/server/Systems/TicketSystem.luau`:
  - Lines 85-100: `SCAM_SENDERS_BY_TYPE` and `LEGIT_SENDERS_BY_TYPE` matching Directory records.

## 5. Out of Scope
- Editable contacts or adding new entries (read-only reference).
- Live audio phone dialer (verification is done visually by cross-referencing).
