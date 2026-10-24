# Zero Trust: Game Design & Hackathon Blueprint
**Theme:** "SaseHacks for good" — Creating positive change through digital literacy and cyber defense.
**Genre:** Papers, Please Style Office Defense / Simulation

---

## 1. Core Premise & Narrative
Instead of playing the scammer (like other popular titles), players flip the script to become the **corporate defense desk** protecting businesses and communities from social engineering, phishing, and financial fraud. 

*   **The Stakes:** You manage the company budget and security queue. Every approved scam drains company funds; hitting $\$0$ causes the company to go under, resulting in team-wide game over ("everyone is fired").
*   **The Schedule:** A 5-day work week. Each shift runs from 9:00 AM to 5:00 PM (accelerated time scale where 1 real minute = 1 in-game hour, making a full shift 8 minutes).

---

## 2. Gameplay Flow & Progression Loop

1. **The Lobby / Break Room:** Players spawn in a shared office lobby. 
2. **The Briefing Room:** An arrow points players to the briefing room board where they review:
   * Daily quotas for problems fixed / scams blocked.
   * Company level / difficulty tier (Local Business $\to$ Small Business $\to$ Medium Business $\to$ Large Corporation $\to$ Government).
   * Active threat briefings and red flags to watch out for.
   * Current company profit / budget.
3. **The Workstation:** Players walk to their individual desks and log into their computer terminal. The entire gameplay shifts to an immersive desktop UI.
4. **The Shift (9:00 AM – 5:00 PM):**
   * Process incoming tickets, emails, chat messages, and phone calls.
   * Investigate using specialized desktop tools.
   * Make decisions: **[Send to Higher Up]** (escalate safely, costing time) or **[Reject]** (block scams, risk small penalties if false positive).
5. **End of Day Review:** Head back to the break room to see the daily report (scams caught, money saved, budget remaining) and spend earned trust on security upgrades.

---

## 3. Computer Workstation UI & Apps

Once seated at the computer terminal, the player accesses a multi-app desktop operating system:

*   **Email Inbox:** Receives incoming requests, vendor invoices, fake CEO wires, and phishing links.
*   **WireConnect (Remote Desktop):** Allows players to connect to employee computers to inspect suspicious activity or check for malware.
*   **Chat Messaging & Calling App:** Handles live communication. Incoming calls trigger a pop-up transcript where players must pick the correct dialogue choices to test the caller.
*   **Directory App:** Quick reference guide for employee IDs, verified vendor phone numbers, and company policies.
*   **Company Banking Ledger:** Real-time visual display of the company budget and funds.
*   **Virtual Machine (VM):** A sandboxed window used to safely test suspicious files or scripts.
*   **Dev Tools / URL Inspector:** Clickable tools to inspect link domains for typosquatting (e.g., catching fake look-alike URLs) and check underlying metadata.

---

## 4. Ticket Types & Real-World Scams

The game teaches real-world digital literacy based on CISA, FTC, and FBI IC3 guidelines:
*   **Fake CEO Wire Request:** Urgent requests to transfer funds under strict secrecy. *(Counter: Verify via known internal phone channel).*
*   **Vendor Invoice Bank Change:** Suppliers claiming a change in deposit accounts. *(Counter: Cross-reference with the Directory app and call the vendor's verified number).*
*   **Gift Card Demand:** Requests for gift cards as corporate payment or fines. *(Counter: Immediate rejection—no legitimate business or agency uses gift cards).*
*   **Phishing Links:** Password reset emails with look-alike domains and bad grammar. *(Counter: Inspect URL, report, and block).*

---

## 5. Hackathon MVP Build Plan (8-Hour Sprint)

*   **Hours 0.5–2 (Environment & UI):** Build the break room, briefing room, and desk terminal. Set up the basic desktop `ScreenGui` with app icons (Inbox, Banking Ledger, URL Inspector).
*   **Hours 2–5 (Core Systems):** Code the server-side ticket generator and client-side UI buttons (`[Reject]`, `[Send to Higher Up]`). Hook up the company budget bar and 9-to-5 clock timer.
*   **Hours 5–7 (Polish & Feedback):** Add visual alerts (red flash and budget drop on missed scams, green confetti on caught scams), audio cues for ringing phones/emails, and the end-of-day summary report.
*   **Hour 8 (Testing & Demo Setup):** Playtest the difficulty ramp, ensure smooth transitions from the break room to the computer UI, and record a snappy 2-minute demo loop for the judges.