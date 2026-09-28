# Installing vibe-safe into a repository

These are the steps an AI coding agent follows when someone pastes the install line from
the README. A person can follow them too. Every step is safe to repeat: run it twice and
nothing doubles. Nothing here changes the application's own code.

Work from the root of the repository you are installing into. `$ANF` below is a checkout
of `https://github.com/andyschwab/anf-skills` (clone it to a temporary folder, or read the
files from GitHub).

## 0. The choice: quick or full

Ask the person one question, in these words or close to them:

> Two ways to check your app. **Quick**: I read the code myself, about ten minutes, nothing
> extra installed. **Full**: a public tool called assay measures it, runs its tests from a
> clean copy, records exactly what was and wasn't checked, and writes you a plain-words
> page; it needs Node installed and takes longer. You can switch later. Which one?

Write the answer to `vibe-safe/MODE` as the single word `quick` or `full` (create the
folder). For `full`, check `node --version` is 20 or later; if it is not, say what to
install, write `quick` for now, and note that the full check is waiting on Node. The
skill's `references/measure.md` reads this file and does the rest at check time; nothing
else is installed for it.

## 1. The contract

The agent contract is the file every AI session in this repository reads first. Find it:
`AGENTS.md`, `CLAUDE.md`, or neither.

- Neither: create `AGENTS.md` with the contents of `$ANF/contract/AGENTS.md`, and create
  `CLAUDE.md` containing the single line `@AGENTS.md` so Claude Code reads the same file.
- One or both exist: append `$ANF/contract/AGENTS.md` to the end of `AGENTS.md` (or
  `CLAUDE.md` if that is the only one), unless it already contains the line
  `anf-skills contract` (then leave it; a newer version replaces the section between the
  comment and the next `## ` heading).

## 2. The skill

Copy `$ANF/skills/vibe-safe/` to `.claude/skills/vibe-safe/` in the repository, replacing
any older copy. Tools other than Claude Code reach it through the contract, which names
the path.

## 3. The secret guard (git hook)

```sh
mkdir -p scripts .githooks
cp $ANF/install/hooks/secret-scan.sh scripts/secret-scan.sh
cp $ANF/install/hooks/pre-commit   .githooks/pre-commit
chmod +x scripts/secret-scan.sh .githooks/pre-commit
git config core.hooksPath .githooks
```

`core.hooksPath` is per clone, so add it where every fresh clone runs it: in
`package.json` a `"prepare": "git config core.hooksPath .githooks"` script; in other
ecosystems, a line in the README's setup section (advisory, say so).

## 4. The CI gate

```sh
mkdir -p .github/workflows
cp $ANF/install/ci/gate.yml .github/workflows/vibe-safe-gate.yml
```

Then pin the actions to commits, so what runs is what was reviewed. Resolve each pin now,
never from memory:

```sh
git ls-remote https://github.com/actions/checkout      refs/tags/v4.2.2
git ls-remote https://github.com/actions/setup-node    refs/tags/v4.1.0
git ls-remote https://github.com/actions/setup-python  refs/tags/v5.3.0
```

Replace `PIN_CHECKOUT`, `PIN_SETUP_NODE` and `PIN_SETUP_PYTHON` in the workflow with the
commit ids printed (the first column, the one for the tag itself or its `^{}` dereference
when both are listed). If `ls-remote` cannot run (no network), leave the placeholders and
say so: the workflow will fail until they are filled, which is the right direction.

The gate needs a test command to exist. If the repository has none, add one now (one test
that exercises the login or the main path) rather than weakening the gate: a gate that
passes on nothing is the thing this whole install exists to prevent.

## 5. The ship hook (Claude Code only)

```sh
cp $ANF/install/claude/ship-gate.sh scripts/ship-gate.sh
chmod +x scripts/ship-gate.sh
mkdir -p .claude
```

Merge `$ANF/install/claude/settings.json` into `.claude/settings.json`: if the file does
not exist, copy it; if it does, add the `PreToolUse` entry to its `hooks` without removing
anything already there. Other tools do not run this hook; for them the contract and the
git-side gates are the safeguards, and the ship check is still done by reading
`references/ship.md`.

## 6. Prove it bites, once

A guard nobody has seen fire is a belief. Do this now, and tell the person what happened:

```sh
printf 'STRIPE_KEY = "sk_live_%s"\n' "$(head -c 24 /dev/zero | tr '\0' a)" > vibe-safe-probe.txt
git add vibe-safe-probe.txt
git commit -m "probe" ; echo "exit: $?"      # expected: refused, exit 1, the scan's message
git rm -q --cached vibe-safe-probe.txt && rm vibe-safe-probe.txt
```

If the commit went through, stop and fix the hook before anything else.

## 7. Switching later

Changing the mode is one line: write `quick` or `full` to `vibe-safe/MODE` and commit it.
When someone with a quick install asks for "the thorough check", do step 0 again.

## 8. Commit, and say what changed

Commit the install as its own commit ("Install vibe-safe: contract, secret guard, CI gate,
ship hook, skill; mode: quick|full"). Then tell the person, in plain words, one line per layer: what it does
for them, and the one thing it will stop them doing by accident. Offer to run the check
(`references/check.md`) next if the repository already has code in it, or to go through
`references/start.md` if it is new.
