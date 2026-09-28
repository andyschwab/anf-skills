# Ship: the check before anything goes outward

This is the one place the person has to stop. Everything before a deploy is reversible; the
deploy, the publish, the first real send, the card on file are not, or not cheaply. The
check is short on purpose so it gets done every time. Do it before: a first deploy, a
deploy after a change to login, data access, sending or payments, connecting a payment or
model provider, giving the link to real users.

If the install has run, a hook blocks deploy-shaped commands until this check has been
recorded for the current commit (`vibe-safe/SHIP.md`, see below). The hook is a seatbelt,
not a lock: the person can bypass it once, and the bypass is written down.

## Part 1: what must not be true (you check these)

Look, do not assume. Each one is **clear** or **open**. Any *open* means: do not ship;
say what would close it, and offer to do it. Do not argue the person out of an *open*.

1. **No secret in the repository or its history.** Search the tree and the history. If
   the app is deployed from a platform that reads secrets from its own settings, the
   repository should hold only the names.
2. **Every route or function that reads or changes data checks who is asking, on the
   server.** Not only in the page. Read the failure branch of the login: a missing or bad
   token must be refused, never defaulted.
3. **Anything that sends, charges, publishes or deletes has a gate**: a confirmation, a
   permission check, an idempotency key, or a person in the loop. And it reports failure
   as failure.
4. **If there is an AI feature:** no single model call both reads untrusted content, sees
   private data, and can act outward without a person confirming. The model key is not in
   the browser.
5. **Errors go somewhere a person will see them.** An error sink or at least logs the owner
   knows how to open.
6. **There is a way back.** The previous version can be put back with one known action,
   and the data has a backup that exists somewhere the owner can point to.
7. **The tests that exist were run, now, on this commit, and they passed.** If there are no
   tests for the login and the effects, say so; it is not a blocker for a first deploy to
   a handful of people, but it is written into the record.

## Part 2: what only the person knows (you ask, one at a time)

Ask these plainly, one per message, and accept "I don't know" as an answer written down as
`unknown`. Roles, never names. Never a secret.

1. **Accounts.** For hosting, the database, the domain, email or SMS, payments, and any
   model provider: is it a personal account or an organisation's, and who else can log
   in? A live app on one personal login is a risk to write down, not a blocker.
2. **Money.** Which accounts are metered (model providers, hosting, database), what pays,
   and is there a spending alert on each? A model key with no cap is how a bill surprises
   someone. Offer to set the alert now, before shipping, and say where in the provider's
   console it lives.
3. **People.** Who else could deploy, and from where? Who could restore from the backup,
   and has anyone ever tried?
4. **Data.** Whose personal data will this hold, and does the product need all of it? If
   it holds other people's data, say once that a person with an engineering background
   should look before real users arrive, and that this record is what to show them.
5. **The exit.** If this goes wrong in the first hour, what is the one thing the person
   will do? (Turn it off, roll back, revoke a key.) Make sure they can, and write it down.

## Part 3: the record

Write `vibe-safe/SHIP.md` in the repository, dated, for the commit about to ship:

```markdown
# Ship check, <date>, commit <sha>

approved_by: <role, e.g. founder>
status: clear | shipped-with-open-items

## Must not be true
1. secrets: clear | open (<where>)
2. authorization: clear | open (<where>)
3. gates on effects: clear | open (<where>)
4. AI feature: clear | open | none
5. errors reach a person: clear | open
6. way back: clear | open
7. tests run on this commit: passed | failed | none

## The person's answers
accounts: …
money: … (alerts: set | not set)
people: …
data: …
exit: …

## Open items shipped anyway (if any)
- <item>: <the person's reason, in their words>
```

Commit it with the code that ships. The deploy hook reads the commit id from this file; a
record for an older commit does not count, so a change after the check means checking
again. That is the point: the record is for *this* version.

## The one named exit

If the person says "ship it anyway" with an item open, that is their call: they own the
app. Write the item and their reason into the record under *Open items shipped anyway*,
say in one sentence what could happen, and proceed. Never argue past that sentence, never
quietly leave the item out of the record, and never bypass the hook for them without the
record. A shipped open item is not forgotten: it is the first thing on the next check.
