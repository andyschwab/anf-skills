#!/bin/sh
# anf-skills regression: installs the guards into a throwaway repository and asserts every
# path the hooks have. Hermetic: no network, no fixtures, POSIX sh + git + GNU grep.
# Usage: sh tests/run.sh      (exit 0 all pass; exit 1 with the failed cases listed)
set -u
ANF=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d)
trap 'rm -rf "${T:?}"' EXIT
fail=0; n=0
check() { # check "<name>" <expected-exit> <actual-exit>
  n=$((n+1))
  if [ "$2" = "$3" ]; then echo "  ok   $1"; else echo "  FAIL $1 (expected exit $2, got $3)"; fail=1; fi
}
gate() { printf '{"tool_input":{"command":"%s"}}' "$1" | sh scripts/ship-gate.sh >/dev/null 2>&1; echo $?; }
G='git -c user.name=t -c user.email=t@t -c commit.gpgsign=false'
# Key-shaped strings are generated, never written, so this file passes the scan itself.
fake() { printf '%s%s' "$1" "$(head -c "$2" /dev/zero | tr '\0' "$3")"; }

cd "$T" && git init -q -b main . && echo "# app" > README.md && git add README.md && $G commit -qm init
echo "== syntax"
for f in "$ANF"/install/hooks/secret-scan.sh "$ANF"/install/hooks/pre-commit "$ANF"/install/claude/ship-gate.sh; do
  sh -n "$f"; check "sh -n $(basename "$f")" 0 $?
done

echo "== install (INSTALL.md steps 1-3, 5)"
cp "$ANF/contract/AGENTS.md" AGENTS.md; echo '@AGENTS.md' > CLAUDE.md
mkdir -p .claude/skills scripts .githooks; cp -r "$ANF/skills/vibe-safe" .claude/skills/
cp "$ANF/install/hooks/secret-scan.sh" scripts/; cp "$ANF/install/hooks/pre-commit" .githooks/; cp "$ANF/install/claude/ship-gate.sh" scripts/
chmod +x scripts/*.sh .githooks/pre-commit; git config core.hooksPath .githooks
git add -A; $G commit -qm install; check "install commits clean" 0 $?

echo "== secret scan"
printf 'STRIPE_KEY = "%s"\n' "$(fake sk_live_ 24 a)" > probe.txt; git add probe.txt
$G commit -qm probe >/dev/null 2>&1; check "commit with a provider key is refused" 1 $?
git rm -q --cached probe.txt; rm probe.txt
printf 'export const settings = { backupApiKey: %s%s%s };\n' "'" "$(fake nbx_ 36 Q)" "'" > settings.mjs; git add settings.mjs
sh scripts/secret-scan.sh --staged >/dev/null 2>&1; check "camelCase apiKey with a long quoted value is caught" 1 $?
git rm -q --cached settings.mjs; rm settings.mjs
printf 'API_KEY=\nDATABASE_URL=\n' > .env.example; git add .env.example
sh scripts/secret-scan.sh --staged >/dev/null 2>&1; check ".env.example (names only) passes" 0 $?
printf 'API_KEY=%s\n' "$(fake sk_live_ 24 b)" > .env; git add -f .env
sh scripts/secret-scan.sh --staged >/dev/null 2>&1; check ".env is refused by its name" 1 $?
git rm -q --cached .env; rm .env
printf 'const url = "postgres://app:%s@db.internal/app";\n' "$(fake p 12 x)" > db.js; git add db.js
sh scripts/secret-scan.sh --staged >/dev/null 2>&1; check "connection string with a password is caught" 1 $?
git rm -q --cached db.js; rm db.js
printf 'const example = "%s"; // secret-scan:allow\n' "$(fake sk_test_ 20 c)" > ex.js; git add ex.js
sh scripts/secret-scan.sh --staged >/dev/null 2>&1; check "secret-scan:allow marker passes a line" 0 $?
git rm -q --cached ex.js; rm ex.js
printf 'x = "%s"\n' "$(fake sk_live_ 24 d)" > probe2.txt; git add probe2.txt
ANF_ALLOW_SECRET=1 ANF_BYPASS_REASON=test $G commit -qm probe2 >/dev/null 2>&1; check "ANF_ALLOW_SECRET=1 bypass commits" 0 $?
grep -q 'secret-scan bypassed' vibe-safe/bypass.log; check "bypass is written to vibe-safe/bypass.log" 0 $?
git ls-files --error-unmatch vibe-safe/bypass.log >/dev/null 2>&1; check "bypass log is committed with the bypass" 0 $?
sh scripts/secret-scan.sh --tree >/dev/null 2>&1; check "--tree finds the bypassed key in the tree" 1 $?
git rm -q probe2.txt; $G commit -qm cleanup >/dev/null 2>&1
mv scripts/secret-scan.sh scripts/secret-scan.off; echo x > f.txt; git add f.txt
$G commit -qm nohook >/dev/null 2>&1; check "missing scan script fails closed" 1 $?
mv scripts/secret-scan.off scripts/secret-scan.sh; git rm -q --cached f.txt; rm f.txt

echo "== ship gate"
check "vercel --prod blocked without a record"           2 "$(gate 'npx vercel --prod')"
check "firebase deploy blocked"                          2 "$(gate 'firebase deploy --only hosting')"
check "supabase db push blocked"                         2 "$(gate 'supabase db push')"
check "chained deploy (npm test && fly deploy) blocked"  2 "$(gate 'npm test && fly deploy')"
check "npm test passes"                                  0 "$(gate 'npm test')"
check "git push feature branch passes"                   0 "$(gate 'git push -u origin feature/x')"
check "git push --force-with-lease to a branch passes"   0 "$(gate 'git push --force-with-lease origin claude/foo')"
check "git push origin main blocked"                     2 "$(gate 'git push origin main')"
check "git push origin HEAD:main blocked"                2 "$(gate 'git push origin HEAD:main')"
check "bare git push on main blocked"                    2 "$(gate 'git push')"
git checkout -q -b feature/y
check "bare git push on a feature branch passes"         0 "$(gate 'git push')"
git checkout -q main
mkdir -p vibe-safe; printf '# Ship check, 2026-01-01, commit %s\n' "$(git rev-parse --short HEAD)" > vibe-safe/SHIP.md
check "record naming HEAD clears the gate"               0 "$(gate 'npx vercel --prod')"
printf '# Ship check, 2026-01-01, commit 0000000\n' > vibe-safe/SHIP.md
check "record for another commit does not clear it"      2 "$(gate 'npx vercel --prod')"
rm vibe-safe/SHIP.md
check "ANF_SHIP_BYPASS=1 in the command passes once"     0 "$(gate 'ANF_SHIP_BYPASS=1 vercel --prod')"
grep -q 'ship gate bypassed' vibe-safe/bypass.log; check "ship bypass is logged" 0 $?
check "empty command passes"                             0 "$(printf '{"tool_input":{}}' | sh scripts/ship-gate.sh >/dev/null 2>&1; echo $?)"

echo "== skill and contract shape"
head -1 "$ANF/skills/vibe-safe/SKILL.md" | grep -q '^---$'; check "SKILL.md has frontmatter" 0 $?
grep -q '^name: vibe-safe$' "$ANF/skills/vibe-safe/SKILL.md"; check "SKILL.md name matches the directory" 0 $?
grep -q '^description: ' "$ANF/skills/vibe-safe/SKILL.md"; check "SKILL.md has a description" 0 $?
for r in check start ship why stacks; do if [ -f "$ANF/skills/vibe-safe/references/$r.md" ]; then rc=0; else rc=1; fi; check "references/$r.md exists" 0 $rc; done
[ "$(wc -l < "$ANF/skills/vibe-safe/SKILL.md")" -lt 500 ]; check "SKILL.md under 500 lines" 0 $?
grep -q 'anf-skills contract' "$ANF/contract/AGENTS.md"; check "contract carries its install marker" 0 $?
grep -Eq '\b(TODO|CHANGELOG|## (Status|History))\b' "$ANF/contract/AGENTS.md"; check "contract is present-tense (no todo/history)" 1 $?
grep -q 'PIN_CHECKOUT' "$ANF/install/ci/gate.yml"; check "gate template keeps its pin placeholders" 0 $?

echo; [ $fail -eq 0 ] && echo "all $n checks passed" || echo "FAILED (of $n checks)"; exit $fail
