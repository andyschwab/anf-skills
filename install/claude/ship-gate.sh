#!/bin/sh
# vibe-safe ship gate: a Claude Code PreToolUse hook on Bash.
# Deploy-shaped commands stop until the ship check is recorded for the current commit
# (vibe-safe/SHIP.md names it). Exit 2 blocks the command and hands the message to the
# agent, which then runs the ship check (references/ship.md). Anything else exits 0.
# Bypass once, visibly: put ANF_SHIP_BYPASS=1 in the command itself
#   ANF_SHIP_BYPASS=1 vercel --prod
# The bypass is appended to vibe-safe/bypass.log. This is a seatbelt, not a lock.
set -u
input=$(cat)

# The command, out of the hook's JSON. jq if present, node if present, else a rough cut.
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
elif command -v node >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write((JSON.parse(s).tool_input||{}).command||"")}catch{}})')
else
  cmd=$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(\([^"\\]\|\\.\)*\)".*/\1/p')
fi
[ -z "$cmd" ] && exit 0

deploy_shaped='(^|[;&|[:space:]])(npx[[:space:]]+)?(vercel([[:space:]]+(--prod|deploy))?|netlify[[:space:]]+deploy|fly(ctl)?[[:space:]]+deploy|gcloud[[:space:]]+(run|app|functions)[[:space:]]+deploy|firebase[[:space:]]+deploy|supabase[[:space:]]+(db[[:space:]]+push|functions[[:space:]]+deploy)|heroku[[:space:]]+(container:push|container:release)|railway[[:space:]]+up|wrangler[[:space:]]+(deploy|publish)|eb[[:space:]]+deploy|serverless[[:space:]]+deploy|sls[[:space:]]+deploy|sst[[:space:]]+deploy|aws[[:space:]]+(s3[[:space:]]+sync|lambda[[:space:]]+update-function-code|cloudformation[[:space:]]+deploy)|terraform[[:space:]]+apply|pulumi[[:space:]]+up|docker[[:space:]]+push|kubectl[[:space:]]+(apply|rollout)|helm[[:space:]]+(install|upgrade)|cap[[:space:]]+(production|staging)[[:space:]]+deploy|amplify[[:space:]]+publish|stripe[[:space:]]+.*--live)([[:space:]]|$)'

matched=0
if printf '%s' "$cmd" | grep -Eq "$deploy_shaped"; then
  matched=1
elif printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+push'; then
  # A push to the main branch deploys on git-connected hosts. Pushing a feature branch is
  # not shipping.
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  # The refspec is the last non-option word after "push"; with none, it is the current branch.
  refspec=$(printf '%s' "$cmd" | sed -n 's/.*git[[:space:]]\{1,\}push//p' | tr ' ' '\n' | grep -v '^-' | grep -v '^$' | sed -n '2p' | sed 's/^.*://')
  [ -z "$refspec" ] && refspec="$branch"
  case "$refspec" in main|master|production|prod|HEAD) matched=1 ;; esac
fi
[ $matched -eq 0 ] && exit 0

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
head=$(git rev-parse HEAD 2>/dev/null || echo "")
short=$(printf '%s' "$head" | cut -c1-7)
record="$root/vibe-safe/SHIP.md"

if [ -n "$head" ] && [ -f "$record" ] && grep -Eq "commit[[:space:]]+\`?$short" "$record"; then
  exit 0
fi

if printf '%s' "$cmd" | grep -q 'ANF_SHIP_BYPASS=1'; then
  mkdir -p "$root/vibe-safe"
  printf '%s  ship gate bypassed for commit %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${short:-unknown}" "$(printf '%s' "$cmd" | cut -c1-120)" >> "$root/vibe-safe/bypass.log"
  echo "ship-gate: bypass recorded in vibe-safe/bypass.log; commit it with the deploy." >&2
  exit 0
fi

cat >&2 <<MSG
ship-gate: this command looks like a deploy or publish, and there is no ship check recorded
for the current commit (${short:-no commit}). Do the ship check first: read
.claude/skills/vibe-safe/references/ship.md, go through it with the person, write
vibe-safe/SHIP.md naming commit ${short:-<sha>}, commit it, then run this command again.
If the person decides to ship without it, they can say so and you run the command with
ANF_SHIP_BYPASS=1 in front of it; the bypass is written to vibe-safe/bypass.log.
MSG
exit 2
