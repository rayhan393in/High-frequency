# Release test matrix — pending unless stated

| Area | Required checks |
|---|---|
| Auth | Registration, verification, password reset, logout, expired cookie, no unauthenticated RPC access |
| Roles | Student cannot edit role/publish or query keys. Admin can publish valid draft. Unknown account sees no private records. Compare two authenticated users and one staff user. |
| Schedule | Before-open and exact-close rejected; Asia/Dhaka date rollover; earliest of global close and duration used; screenshot/UI time matches server. |
| Live exam | Resume same session, four options shown without key; reject foreign question position or session; concurrent autosave/submit; duplicate submit idempotent; browser closed at deadline then worker grades; pre-release details unavailable. |
| Results | Correct, incorrect, unanswered, penalty, exact fractional marks and repeat consistency; leaderboard rank/ties only after release. |
| Catalog | Source/version traceability, compare every BPSC entry against original document, import duplicates, verify no historical stats from unverified source. |
| Routine | Calendar fit, days off, focus weak topics, nonduplicate schedule, revisions, edits, permissions. |
| PDFs | Download actual PDF; Bengali shaping/embedding, A4 pagination, print quality, private access. |
| Releases | Mobile/desktop browser runs; production build; load and isolation validation against deployed staging. |
