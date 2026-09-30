# Supabase setup

Everything the app needs on the server, in order. Each SQL file is safe to run
more than once.

## 1. Database

In the Supabase dashboard, open **SQL Editor → New query** and run:

1. `schema.sql`: tables, row-level security, the sign-up trigger.
2. `002_complete_app.sql`: fixes and everything added since. The app
   **won't work fully without this**. Memories, results, bills and the host
   reveal all rely on it. It:
   - fixes two access bugs (a policy on `group_members` that recursed, and
     solo sessions that any signed-in user could read);
   - stores the host's filters on the session, and records when everyone has
     voted;
   - makes results one row per place;
   - adds "Didn't go" (`memory_dismissals`), UPI IDs (`payment_details`) and
     bills (`bills`, `bill_shares`, plus the functions that change them);
   - turns on realtime for every table the app watches;
   - stops phone numbers and push tokens being readable by other users.
3. `003_lock_down_functions.sql`: makes the bill functions signed-in only,
   and fixes a check in `set_bill_shares` that let signed-out callers through.

## 2. Push notifications

Pushes go out from one Edge Function, `notify`, which database webhooks call
when something happens. You need the
[Supabase CLI](https://supabase.com/docs/guides/cli) and a Firebase project
that has the Android app registered (see the main README).

**Service account.** In the Firebase console, open **Project settings →
Service accounts → Generate new private key**. Keep the downloaded JSON
private.

**Secrets and deploy.** From the project folder:

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase secrets set FCM_SERVICE_ACCOUNT="$(cat path/to/service-account.json)"
supabase secrets set WEBHOOK_SECRET=<any long random string>
supabase functions deploy notify --no-verify-jwt
```

`--no-verify-jwt` is needed because webhooks don't send a user token. The
function checks `WEBHOOK_SECRET` instead.

**Webhooks.** In **Database → Webhooks → Create a new hook**, add one hook per
row below. Every hook uses:

- type **Supabase Edge Functions**, function `notify`, method POST;
- an HTTP header `x-webhook-secret` set to the same `WEBHOOK_SECRET`.

| Table           | Events           | What it sends                              |
|-----------------|------------------|--------------------------------------------|
| `group_members` | Insert           | "Asha joined the crew" to the crew         |
| `sessions`      | Insert, Update   | New session, swiping open, winner revealed |
| `swipes`        | Insert           | "Everyone's voted" to the host, once       |
| `bills`         | Insert           | "You owe ₹600" to each person on the bill  |

Notification text is English and set in the function. The app's own screens
use `lib/l10n/`.

## Checking it works

- Sign in on two phones, join the same crew: the first phone gets "… joined
  the crew".
- Logs: **Edge Functions → notify → Logs**. A 403 there means the webhook's
  `x-webhook-secret` doesn't match `WEBHOOK_SECRET`.
- No notification at all: check the person's `profiles.fcm_token` is set.
  The app saves it after sign-in, once notification permission is granted.
