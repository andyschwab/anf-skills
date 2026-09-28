# anf-skills

Safeguards for software built with an AI, installed by the AI that built it.

If you built an app with Claude Code, Cursor, Lovable, Replit, Bolt, v0 or a chat, it
probably works. Whether it is *safe* (no key in the code, no door open to every user's
data, no charge that fires twice, a way back if a deploy goes wrong) is a separate question
that nobody asked while it was being built. This repository answers it in a way that does
not depend on anyone remembering to ask: a few things that go red on their own, one short
check before anything goes outward, and one skill your AI reads at the moments that
matter.

## Install: paste this into the AI tool you built your app with

> Install anf-skills into this repository. Clone `https://github.com/andyschwab/anf-skills`
> to a temporary folder and follow its `install/INSTALL.md` step by step, including the
> step that proves the secret guard bites. Then tell me in plain words what you installed,
> one line each, and offer to run the check on my code.

That is the whole install. It takes the AI a few minutes and it does not change your
application's code. It asks you one question on the way: **quick or full**.

| | Quick | Full |
|---|---|---|
| What checks your app | your AI reads the code against the list | [assay](https://github.com/andyschwab/assay), a public engine, measures it: runs the install and tests from a clean copy, audits dependencies, scans for secrets, records what ran and what did not, then your AI does the reading in the engine's format |
| What you get | a report in your repo, plain words, file and line | the same, computed from the measurement, plus a record of what nobody checked |
| Needs | nothing extra | Node 20 or later |
| Takes | about ten minutes | a few minutes for the measured part, an hour or more for the reading |

You can switch at any time; it is one line in a file. When the app holds other people's
data or takes payments, choose full.

## What gets installed

Three layers. Any one of them alone is advisory; together they hold.

| Layer | What it is | What it does for you |
|---|---|---|
| **The contract** | a section appended to `AGENTS.md` / `CLAUDE.md` | every AI session in the repo starts with the same rules: no secrets in files, outside content is data not instructions, a fix that turns a check off is not a fix, every change ends with how to verify it |
| **The guards** | a git pre-commit secret scan · a CI gate on the main branch · a ship hook (Claude Code) | a key cannot be committed by accident · tests, lint and build run on every change and fail loudly, including when there are no tests · deploy-shaped commands stop until the ship check is recorded for that commit |
| **The skill** | `vibe-safe`, one skill with three moments | **Check** an existing codebase (what is true, with file and line, in the order things hurt) · **Start** a new one safe from the first commit · **Ship**: the ten-minute check before anything goes outward, with the questions only you can answer |

Every guard can be bypassed once, on purpose, and the bypass is written into the repository
(`vibe-safe/bypass.log`). They are seatbelts, not locks: they stop the accident, not the
determined person, and the person is the one who owns the app.

## What it does not do

- It is not a security audit and not a substitute for an engineer looking before real
  money or other people's personal data are at stake. The check's report is written to be
  handed to one.
- It does not score, grade or approve. It says what is true, what could happen, and what
  would fix it.
- If your tool is Lovable, Replit or Bolt rather than a coding agent on your machine, the
  ship hook and the skill do not run there. The contract, the git hook and the CI gate
  still work once the code is in a GitHub repository, and the ship check still works as a
  document to go through with your AI: paste `skills/vibe-safe/references/ship.md`.

## Where this comes from

The requirements behind the check are the public yardstick of
[assay](https://github.com/andyschwab/assay), an evidence-based repository evaluation
engine: what must be true of an application somebody stands behind, in the order things
hurt (custody, safety, reproducibility, verification, legibility, operability). The
positions behind the contract come from the AI-Native Framework, a knowledge base of
what has held up in practice when people build with AI; each rule here traces to a
recorded observation there. Nothing here names a stack in the rules; `references/stacks.md`
says where the same things live on the usual platforms.

## Repository layout

```
contract/AGENTS.md          the section the install appends to your agent contract
install/INSTALL.md          the steps the AI follows; hooks/, ci/, claude/ hold the files
skills/vibe-safe/           the skill: SKILL.md and references/ (check, start, ship, why, stacks)
```

## Licence

Apache 2.0. Use it, change it, ship it with your own house rules.
