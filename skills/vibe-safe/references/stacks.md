# Stacks: where the same things live on the usual platforms

The check, start and ship references never name a stack. This file says where to look on
the ones people usually build with. Read the one section that applies. If the stack in
front of you is not here, the requirements are the same; find the equivalent.

## Next.js with Supabase, deployed on Vercel

- **Secrets.** Server-only values must not start with `NEXT_PUBLIC_`; anything that does
  is in the browser bundle. `SUPABASE_SERVICE_ROLE_KEY` in a client component or a
  `NEXT_PUBLIC_` variable is a master key in every visitor's browser. Values live in
  Vercel's project settings, the repo holds `.env.example`.
- **Authorization.** The anon key is public by design; the protection is Row Level
  Security (RLS) on every table. A table with RLS off, or a policy `USING (true)`, is open
  to anyone with the anon key, which is everyone. Check `supabase/migrations/*.sql` for
  `enable row level security` and the policies; check the dashboard was not the only place
  they were set. Route handlers and server actions must read the user from the session,
  not from the request body.
- **Effects.** Server actions and route handlers that send (Resend, Stripe, webhooks): the
  auth check happens inside them, not in the page that calls them. Stripe webhooks verify
  the signature.
- **Deploy.** Vercel deploys from git; that is the one command. Check the production
  branch and that preview deployments do not point at the production database.
- **Schema.** `supabase/migrations/` should exist and replay; a schema that only exists in
  the Supabase dashboard is the dashboard-schema shape.
- **Costs.** Vercel spend management, Supabase usage alerts, and the model provider's
  usage limit, each set in its own console.

## Node with Express (or Fastify, Hono)

- **Secrets.** `process.env` reads versus `.env.example`; `dotenv` in production is a
  smell; `config.js` with literal keys is the key-in-file shape.
- **Authorization.** Middleware per route or router, and the failure branch of it: what
  happens when `req.headers.authorization` is missing. Look for default users.
- **Effects.** `fetch`/`axios` calls to outside services: awaited? errors handled? Return
  values checked before reporting success? Any `.catch(() => {})`.
- **Deploy.** A `Procfile`, `Dockerfile`, or platform config; a `start` script; a
  documented command. Deploys from `node server.js` on a laptop do not count.
- **Tests.** `npm test` runs something; `describe.skip`, `if (!process.env.X) return`, or
  a test file with only happy paths.

## Python with FastAPI (or Flask, Django)

- **Secrets.** `os.environ` reads versus `.env.example`; `settings.py` with literal keys;
  `SECRET_KEY` committed.
- **Authorization.** FastAPI `Depends` on every data route; Django views without
  `login_required` or permission checks; Flask routes with no decorator. Object-level
  checks (this user owns this row), not only "is logged in".
- **Effects.** `requests`/`httpx` calls: `raise_for_status`, retries with idempotency,
  background tasks whose failures go nowhere.
- **Schema.** Alembic or Django migrations present and replaying from empty.
- **Deploy.** `uvicorn`/`gunicorn` behind a documented command or container; not a
  terminal on a laptop.

## Firebase (Firestore, Auth, Cloud Functions)

- **Secrets.** Firebase web config is public by design; the protection is the security
  rules, not the config. Function secrets in `functions` config or Secret Manager, not in
  code.
- **Authorization.** `firestore.rules` and `storage.rules`: `allow read, write: if true`,
  or rules with an expiry date that has passed (the "test mode" default), are the open
  database shape. Rules must exist in the repo and be deployed, not only edited in the
  console.
- **Effects.** Cloud Functions that send or charge: auth checked inside the function
  (`context.auth`), idempotent on retries (functions retry).
- **Costs.** Budget alerts in Google Cloud billing; Firestore reads can run away.

## AI features, on any stack

- The model key is read on the server only. An endpoint the browser calls, which checks
  the user and caps spend per user, sits in front of the model.
- The call that reads untrusted content does not hold the tool that acts outward, or a
  person confirms between the model's reply and the action. Look for a loop that parses
  the model's text for a command and executes it.
- Model provider usage limits set, and a spending alert.
- Prompts and outputs logged somewhere a person can read when something goes wrong.
