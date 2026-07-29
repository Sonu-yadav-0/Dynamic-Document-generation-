# Google Drive Integration: The Full Debugging Story

This documents every error hit while getting the Quote → Google Drive upload feature working end to end, in the order they happened, why each one occurred, and exactly how it was fixed. Written as a narrative so the reasoning survives, not just the fix — the same category of mistake (a misnamed custom metadata record, a mixed-up Auth Provider field) is easy to reintroduce during future changes if only the "answer" is recorded.

## Chapter 1 — The FATAL_ERROR that started it all

**Symptom:** Clicking "Download PDF/Word" on a Quote threw:
```
FATAL_ERROR Class.GN_Quote_Generation.generateAndAttachQuoteDocument: line 33, column 1
```

**Investigation:** The line number alone didn't say much — line 33 was just the closing brace of a `try/catch` that wraps everything and rethrows as `AuraHandledException`. To find the *real* cause, we pulled the actual debug log from the org:

```
sf apex list log --target-org ERA
sf apex get log --target-org ERA --log-id <id>
```

Grepping for `EXCEPTION_THROWN` in the raw log showed the true origin:
```
EXCEPTION_THROWN|[46]|System.NullPointerException: Attempt to de-reference a null object
```
at `GoogleDriveService.getAccessToken`, on the line reading `settings.Service_Account_Email__c`. The log also showed `VARIABLE_ASSIGNMENT|[10]|settings|null|` — the metadata record lookup was returning `null`.

**Root cause:** `GoogleDriveService.cls` called `Google_Drive_Setting__mdt.getInstance('Default')`, but no record named `Default` existed in the org. A `SELECT DeveloperName FROM Google_Drive_Setting__mdt` query showed the actual (only) record was named `Google_Drive_Setting` — a leftover from earlier setup, never renamed to match what the code expected, and the correctly-named `Default` record sitting in the local source had simply never been deployed.

**Fix:** Changed the code to look up the record that actually existed:
```apex
Google_Drive_Setting__mdt.getInstance('Google_Drive_Setting')
```
and added a null-check that throws a clear `GoogleDriveException` instead of letting it NPE, so any future name mismatch fails loudly instead of producing a cryptic `FATAL_ERROR`.

**A detour that didn't pan out:** Before landing on the code fix, we tried the "correct" fix of deploying the missing `Default` custom metadata record to the org instead. Every attempt — `sf project deploy start` with the single file, with the parent object included, with a hand-built raw Metadata API zip, at different API versions — failed identically with:
```
UNKNOWN_EXCEPTION: An unexpected error occurred. Please include this ErrorId...
```
Deploying an unrelated Remote Site Setting worked fine in the same session, proving the deploy pipeline itself was healthy — this was specific to *any* Add/Update of a `Google_Drive_Setting__mdt` record via the Metadata API on this org, add or update, regardless of content. That's a platform-side quirk of this particular org, not something fixable from our end, which is why every subsequent metadata *value* fix in this story had to be done by hand through Setup UI instead of `sf project deploy start`.

## Chapter 2 — The record got renamed by accident

Following the guidance above, the plan was: fix the `Certificate_Developer_Name__c` field value (it had a casing mismatch — `GoogleDriveServiceAccount` vs the actual deployed certificate `googledriveserviceaccount`) by hand via **Setup → Custom Metadata Types → Manage Records**.

**What actually happened:** the *record's own* system "Developer Name" field got edited instead of the custom "Certificate Developer Name" field further down the page — two similarly-labeled fields on the same edit screen. The record's name changed from `Google_Drive_Setting` to `googledriveserviceaccount`.

**Symptom:** The code's `getInstance('Google_Drive_Setting')` call now returned `null` again — this time hitting our own newly-added guard:
```
Google_Drive_Setting__mdt record "Google_Drive_Setting" is not configured.
```

**Fix:** Rather than risk another manual edit on this broken-deploy metadata type, updated the code to match the record's new (accidental but now real) name: `getInstance('googledriveserviceaccount')`.

## Chapter 3 — Google rejects the upload: no storage quota

With the metadata lookup finally resolving, the callout reached Google for the first time and got:
```
403: Service Accounts do not have storage quota. Leverage shared drives.
```

**Why this happens:** service accounts have zero personal Drive storage. Any file a service account *creates* is owned by the service account and billed against its own quota — regardless of what folder it's placed in or who that folder belongs to. Google only pools storage away from the individual creator in two cases: **Shared Drives** (storage belongs to the Shared Drive itself) or **Domain-Wide Delegation** (the service account impersonates a real Workspace user). Both require **Google Workspace** — neither is available on a plain `@gmail.com` account.

**First attempted workaround (didn't work):** shared a personal "My Drive" folder with the service account's email as Editor. This doesn't touch the actual cause — folder permissions don't change who owns newly-created files — so it would have failed with the identical 403. Along the way we also caught two side issues in that share dialog worth noting for hygiene: the entry had drifted into a "Pending owner" transfer state (a transfer a service account can never accept), and General Access had been left at "Anyone with the link: Editor" (public write access) — both worth avoiding regardless of the auth approach chosen.

**Real decision:** since the target Drive is a personal Gmail account, Shared Drives and delegation are both off the table. The only remaining path is to stop authenticating as a service account and instead authenticate as the real Gmail user via OAuth 2.0, so uploaded files are owned by an account that actually has quota.

## Chapter 4 — Standing up OAuth via Salesforce Auth Provider + Named Credential

The plan: a Salesforce **Auth. Provider** (OpenID Connect, pointed at Google) backing a **Named Credential** (`GoogleDrive`), so Salesforce handles the OAuth dance and token refresh declaratively — Apex will eventually just call `callout:GoogleDrive/...` with no manual token code at all.

### Error: "Consumer Key" required before we had one to give it

Salesforce's Auth Provider form requires a Consumer Key at save time, but the Google OAuth Client ID (which *is* the Consumer Key) can't be created without first knowing the callback URL Salesforce will use — and that URL is generated *after* saving. Chicken-and-egg.

**Resolution:** the callback URL is actually deterministic — `https://<My Domain>/services/authcallback/<URL Suffix>` — so it could be predicted before ever touching the Auth Provider form: `https://allied-era-dev-ed.develop.my.salesforce.com/services/authcallback/GoogleDriveOAuth`. Created the Google OAuth Client first using that predicted URI, then came back and filled in the Salesforce form with real values.

### Error: "Access blocked: ... has not completed the Google verification process"

The OAuth consent screen was in **Testing** publishing status, and the Gmail account trying to authenticate wasn't yet listed as an approved tester.

**Fix:** Google Cloud Console → OAuth consent screen → Test users → added the Gmail account explicitly.

### Error #1: "We can't log you in because of an authentication error"

Google's side succeeded and redirected back to Salesforce, but Salesforce couldn't complete the identity handshake.

**Root cause:** the Auth Provider's **Default Scopes** only requested `https://www.googleapis.com/auth/drive.file`. Salesforce's OpenID Connect provider type needs an `openid` (and practically `email`) scope to get back an ID token it can parse for identity — without it, the handshake has nothing to resolve and fails with this generic message.

**Fix:** changed Default Scopes (and the Named Credential's own Scope field, which must match) to:
```
openid email https://www.googleapis.com/auth/drive.file
```

### Warning (not an error, but not safe to ignore): "didn't provide a refresh token"

The auth flow completed and stored an access token — but without a refresh token, the Named Credential would silently stop working the moment that access token expired (roughly an hour), since Salesforce would have nothing to renew it with.

**Why it happens:** Google only issues a refresh token on a genuinely fresh consent grant for a given app + scope combination. Having already granted (even partial) access during earlier failed attempts was enough for Google to skip re-issuing one.

**Fix:**
1. Revoked the app's existing grant at `myaccount.google.com/permissions` so the next attempt is treated as first-time consent.
2. Added `access_type=offline&prompt=consent` as query parameters, which forces Google to show full consent and issue a refresh token every time.

### Error #2: "We can't log you in because of an authentication error" (again)

This one took the most digging, because it looked identical to the earlier scope-related error but the scopes were already fixed.

**Investigation:** queried `SetupAuditTrail` for the most recent Named Credential / Auth Provider activity:
```sql
SELECT CreatedDate, Action, Section, Display FROM SetupAuditTrail ORDER BY CreatedDate DESC LIMIT 15
```
This showed a successful `OAuth Token changed for named credential GoogleDrive` entry from *before* the `access_type`/`prompt` change, and nothing successful after it — proving the request itself was now breaking, not just missing a refresh token.

**Root cause, found by reading the Auth Provider detail page carefully:** the `access_type=offline&prompt=consent` query string had been pasted into the wrong field. It landed on:
```
User Info Endpoint URL: https://accounts.google.com/o/oauth2/auth?access_type=offline&prompt=consent
```
instead of the **Authorize Endpoint URL**. The User Info Endpoint is called server-side by Salesforce expecting a JSON profile response — pointing it at Google's HTML authorization page instead returns garbage Salesforce can't parse, breaking login immediately after the redirect.

**Fix:** put each value back in its correct field:
```
Authorize Endpoint URL:  https://accounts.google.com/o/oauth2/auth?access_type=offline&prompt=consent
User Info Endpoint URL:  https://openidconnect.googleapis.com/v1/userinfo
```

### Result

Re-ran the Named Credential's auth flow one more time — successful login, consent granted, and this time **with** a refresh token stored. No further errors.

## Current configuration reference

| Item | Value |
|---|---|
| Auth Provider name | `GoogleDriveOAuth` |
| Auth Provider type | Open ID Connect |
| Callback URL | `https://allied-era-dev-ed.develop.my.salesforce.com/services/authcallback/GoogleDriveOAuth` |
| Authorize Endpoint URL | `https://accounts.google.com/o/oauth2/auth?access_type=offline&prompt=consent` |
| Token Endpoint URL | `https://oauth2.googleapis.com/token` |
| User Info Endpoint URL | `https://openidconnect.googleapis.com/v1/userinfo` |
| Default Scopes | `openid email https://www.googleapis.com/auth/drive.file` |
| Named Credential name | `GoogleDrive` |
| Named Credential URL | `https://www.googleapis.com` |
| Identity Type | Named Principal |
| `Google_Drive_Setting__mdt` record name | `googledriveserviceaccount` (historical accident — see Chapter 2; not renamed back due to the CustomMetadata deploy bug on this org) |

## Chapter 5 — Switching the Apex code over, and closing the loop

With the Named Credential authenticated, `GoogleDriveService.cls` was rewritten to drop the service-account JWT flow entirely:

- `UPLOAD_ENDPOINT` changed from a raw `https://www.googleapis.com/...` URL to `callout:GoogleDrive/upload/drive/v3/files?...` — Salesforce resolves the `callout:` prefix to the Named Credential and attaches a valid OAuth bearer token automatically.
- The manual `request.setHeader('Authorization', 'Bearer ' + accessToken)` line was removed — no longer needed, or possible to set manually, with a Named Credential.
- The entire `getAccessToken` method (`Auth.JWT` / `Auth.JWS` / `Auth.JWTBearerTokenExchange`) was deleted, along with the now-unused `TOKEN_AUDIENCE` constant.
- The metadata record is now only consulted for `Drive_Folder_Id__c` — `Service_Account_Email__c`, `Certificate_Developer_Name__c`, and `Scope__c` are no longer read by this class (auth is fully owned by the Auth Provider/Named Credential now).

**Verified working end to end** via anonymous Apex directly against the org:
```apex
String link = GoogleDriveService.uploadFile('claude-test-upload.txt', Blob.valueOf('hello from apex'), 'text/plain');
```
returned a real Drive file link, confirming the full chain — Apex → Named Credential → Google OAuth → Drive upload — works against the personal Gmail account with no service-account/quota error.

## Outstanding work

None for this integration path. If the `Google_Drive_Setting__mdt` record ever needs a value changed again (e.g. `Drive_Folder_Id__c`), remember the CustomMetadata deploy bug from Chapter 1 is still unconfirmed as fixed on this org — edit it by hand via **Setup → Custom Metadata Types → Manage Records** rather than `sf project deploy start`, and watch out for the "Developer Name" vs custom-field mix-up from Chapter 2.
