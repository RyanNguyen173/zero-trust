---
description: Implement plans/<name>.md, lint, playtest, report
argument-hint: <plan name, e.g. house>
---
Implement `plans/$ARGUMENTS.md` exactly. Touch only what it names; don't re-explore what it already tells you.

- Code plan: write files in `src/`, then run `stylua src` and `selene src` and fix any issues.
- Map plan: build it in Workspace with one `execute_luau` snippet, grouped in the named Model.

Then playtest via the Studio MCP and report only errors and warnings.
Finish with one line of what changed and `Next:` — usually "ask agy: check $ARGUMENTS" for map builds, or "commit" for code.
