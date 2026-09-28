# Measure: the full check, with assay

The quick check (`check.md`) is your reading of the code. The full check is a
**measurement**: [assay](https://github.com/andyschwab/assay), a public, zero-dependency
engine, draws a map of the repository with tools that run offline, measures it against
the same requirements the quick check walks, records what ran and what did not, and
writes an owner page in plain words. The difference for the person: "your AI looked"
becomes "here is what was measured, and here is what nobody measured". Use it when
`vibe-safe/MODE` says `full`, or when the person asks for the thorough version.

Needs: Node 20 or later, git, and the repository checked out. If Node is missing, say so,
fall back to the quick check, and tell the person the full check is one install away.

## 1. Get the engine

```sh
ASSAY=$(mktemp -d)/assay
git clone --depth 1 https://github.com/andyschwab/assay "$ASSAY"
(cd "$ASSAY" && git rev-parse HEAD)      # record this commit in the run's notes
```

Read `$ASSAY/README.md` once; it is the engine's contract and it is short.

## 2. The instrument half (a few minutes, no judgment involved)

```sh
RUN=vibe-safe/runs/$(date +%Y-%m-%d)
node "$ASSAY/routine/run.mjs" . --out "$RUN"
```

This runs the offline instruments (a fresh clone that installs, builds, lints, typechecks
and tests; a dependency audit; a census of the repository's own hygiene; a secrets scan
when `gitleaks` is on the PATH), writes the run record saying what ran and what was
skipped and why, validates the map, and compiles the views and the owner page. If it
fails, read the reason; a tool that errored is recorded as failed, never as clean, and
that is correct. Do not "fix" a failure by removing the instrument.

The run record marks the judgment-bearing scanner (`repo-eval`, the engine's built-in
reading method) as skipped: the routine never runs it. Stopping here is legitimate when
time is short; the owner page will say those requirements were not measured.

## 3. The judgment half (the reading, done by you, in the engine's format)

Open `$ASSAY/map/METHOD.md` and follow it as your method for this repository. It drives
the passes over the seven dimensions; each pass writes its findings to
`$RUN/map/findings/repo-eval-<dimension>.yaml` in the schema it gives, facts with file and
line, strengths as well as gaps, never a severity. When the passes are done, update
`$RUN/map/scanners.yaml` so `repo-eval` reads as having run (the method says how), then:

```sh
node "$ASSAY/assay.mjs" validate "$RUN"     # fails closed on anything malformed; fix, do not skip
node "$ASSAY/assay.mjs" compile  "$RUN"     # re-measures with the full map, rewrites every view
```

This is the long part: an hour or more of reading on a real app. Say so to the person
before starting, and offer the instrument half alone if they would rather.

## 4. Read the owner page to the person

`$RUN/OWNER.md` is the report: what is true, in the order things hurt, with what could
happen, where, what to do, and how to know it is fixed; what could not be told and what
would tell; what holds; what was not looked at. It is computed from the measurement, so
read it as it is. Your job is to add the person's context, not to re-decide anything:

- Say the opening paragraph in your own words, then the first three things under
  *Fix in this order*, then stop and ask what they want to do first.
- For each *Could not tell* row decided by the owner, ask the question; the answers go
  into the packet (`node "$ASSAY/assay.mjs" ask-owner --run "$RUN"` prints the prompt
  pre-filled with what the run found, if they would rather answer in one go).
- Never add a score, a grade, or a verdict. Never soften a *does not hold* into advice.
- If the page and your own reading disagree, the page is the measurement and your
  reading is a claim; say both and cite where you looked.

The rules in `SKILL.md` ("How to carry yourself") apply to every word you say.

## 5. Keep the run

Commit `vibe-safe/runs/<date>/` with the repository. It is the record of what was true on
that commit, the next check compares against it (`--since`), and it is what to hand to
anyone technical who helps later. It contains file paths and line numbers from the
person's own code and nothing else; check that no secret value was written into it
(`sh scripts/secret-scan.sh --tree` runs on the whole tree, the run included).
