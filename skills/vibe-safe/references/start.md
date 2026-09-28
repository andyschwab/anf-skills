# Start: a new repository, safe from the first commit

The cheapest time to install a safeguard is before there is anything to protect. Everything
here goes in before the first feature, takes a few minutes, and never has to be remembered
again. The person does not need to understand each piece; you do, and you tell them in one
line what each one does for them.

The bar for every item is the same: **it goes red on its own when the rule is broken, or it
is labelled as advice.** A rule that only lives in a document is broken by construction,
because nobody rereads documents. So each row below says which it is.

## The install (mechanisms)

Follow `/install/INSTALL.md` from the anf-skills repository if it has not run here yet. It
puts in place:

| What | What it does for the person | Kind |
|---|---|---|
| The contract (`AGENTS.md` / `CLAUDE.md` section) | every AI session in this repo starts with the same rules | routes the agent; advisory on its own |
| Pre-commit secret scan | a key cannot be committed by accident | goes red |
| CI gate on the main branch | the tests, lint and build run on every change and a failure is visible | goes red |
| Ship hook (Claude Code) | deploy-shaped commands stop until the ship check is recorded for this commit | goes red, one logged bypass |
| This skill | the three moments are one name away | routes the agent |

## The application side (do these now, in this order)

1. **`.gitignore` before anything else**, with `.env*`, `*.pem`, `*.key`, the platform's
   local folders, and `node_modules`/`venv`. Verify: `git status` after creating a `.env`
   shows nothing.
2. **`.env.example`** listing every variable the app will read, with a one-line comment
   each and no values. It is the one home of "what this app needs to run". Verify: the
   app refuses to start with a clear message when a required variable is missing (that
   refusal is a mechanism; add it).
3. **A lockfile, committed**, and the runtime version declared (`.nvmrc`,
   `.python-version`, `engines`). Verify: a fresh clone installs the same versions.
4. **A test that runs and a lint that runs**, even if the test is one line, so the CI gate
   has something to gate and nobody has to "add tests later" from zero. Verify: CI green
   on the first push, red when you break the one test on purpose (do this once; it proves
   the gate bites).
5. **Server-side authorization from the first route that touches data.** Decide the rule
   ("a user sees only their rows") and write it where the data is read, not in the page.
   With a hosted database that has row-level policies, turn them on before the first
   table is public. Verify: a request with no token is refused; with another user's token
   sees nothing of theirs.
6. **A place errors go.** An error sink (free tiers exist) or structured logs the owner
   knows how to open. Verify: throw one error on purpose and watch it arrive.
7. **Cost alerts on every metered account the day it is created**, especially model
   providers. This is a setting in the provider's console, not code; it is advisory here,
   so record in `vibe-safe/SHIP.md` when it is set. Verify: the alert email arrives on a
   test threshold.
8. **`docs/ARCHITECTURE.md`, ten lines**: the parts, where data lives, which outside
   services are called. Grows with the app. Advisory.
9. **`docs/RUNBOOK.md`, four headings**: restart, roll back, rotate a key, restore from
   backup. Fill each when the first real answer exists; "not yet known" is an honest
   entry. Advisory, and the ship check reads it.
10. **A README that is true**, meaning its commands run. Keep it to what exists.

## If the app will have an AI feature

Design the split before writing it: which call reads untrusted content, which sees private
data, which can act. No single call gets all three with an outward tool and no person in
between. The model key lives on the server, behind an endpoint that checks who is asking
and caps how much any one caller can spend. Say this to the person in one sentence: "the
AI part can read or act, and a person confirms in between."

## If the app will take payments or hold other people's data

Say once, now, that before real users arrive a person with an engineering background should
look, and that the check report is what to show them. Then build so that review is short.

## Verify the whole thing once

Break one rule on purpose and watch it go red: add a fake key to a file and try to commit.
Then remove it. If the commit went through, the hook is not installed; fix that before the
first feature. A guard that has never been seen to fire is a belief, not a guard.
