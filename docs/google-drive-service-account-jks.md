# Creating `GoogleDriveServiceAccount.jks`

This documents how the Java Keystore (JKS) used by Salesforce's **Certificate and Key Management** was built from a Google service account's JSON key. Salesforce only accepts a full keystore (private key + a certificate bundled together) here — it will not accept the raw JSON that Google Cloud Console gives you. Follow these steps again whenever the service account key is rotated.

## Why a keystore, and why a certificate at all

`GoogleDriveService.cls` authenticates to Google using a JWT signed with the service account's private key (`Auth.JWT` / `Auth.JWS` / `Auth.JWTBearerTokenExchange`). Salesforce's `Auth.JWS` class points at a certificate/key pair stored in **Certificate and Key Management**, and that section only imports keystores (JKS or PKCS12), not a bare private key file.

The certificate paired with the key in the keystore is a **throwaway self-signed certificate** — Google never sees it and doesn't validate it. Google only verifies the JWT signature against the public key it already has on file for the service account (created alongside the private key when the JSON was generated). The certificate exists purely so the keystore container has the cert+key pair format Salesforce's import expects.

## Prerequisites

- `openssl` (ships with Git for Windows / Git Bash — confirm with `openssl version`)
- `keytool` (ships with any JDK — confirm with `keytool -version`)
- Python (or any tool that can parse JSON and unescape `\n` into real newlines)
- The service account's JSON key, downloaded from Google Cloud Console (IAM & Admin → Service Accounts → your account → Keys → Add Key → JSON)

## Step 1 — Extract the private key into a real PEM file

The JSON's `private_key` field is a single-line string with literal `\n` escape sequences, not actual line breaks. Parse it with a JSON-aware tool so the escapes are converted correctly — don't do this with a text editor's find/replace, it's easy to corrupt the key.

```bash
python -c "import json; d=json.load(open('<path-to-downloaded-key>.json')); open('private_key.pem','w',newline='\n').write(d['private_key'])"
```

## Step 2 — Generate a throwaway self-signed certificate for that key

```bash
openssl req -new -x509 -key private_key.pem -out cert.pem -days 3650 -subj "/CN=GoogleDriveServiceAccount"
```

`-days 3650` (10 years) is fine since the certificate's validity is irrelevant to Google — only used to satisfy the keystore format.

## Step 3 — Bundle the key and certificate into a PKCS12 file

```bash
openssl pkcs12 -export \
  -in cert.pem \
  -inkey private_key.pem \
  -certfile cert.pem \
  -out keystore.p12 \
  -name GoogleDriveServiceAccount \
  -passout pass:<CHOOSE_A_PASSWORD>
```

## Step 4 — Convert PKCS12 to JKS

Salesforce's "Import from Keystore" expects a `.jks` file specifically.

```bash
keytool -importkeystore \
  -srckeystore keystore.p12 -srcstoretype pkcs12 -srcstorepass <CHOOSE_A_PASSWORD> \
  -destkeystore GoogleDriveServiceAccount.jks -deststoretype JKS -deststorepass <CHOOSE_A_PASSWORD> \
  -alias GoogleDriveServiceAccount -noprompt
```

## Step 5 — Clean up

Delete the intermediate plaintext files — only the final `.jks` is needed, and it's the last copy of the private key that should be left lying around on disk:

```bash
rm -f private_key.pem cert.pem keystore.p12
```

## Step 6 — Import into Salesforce

1. Setup → Security → **Certificate and Key Management** → **Import from Keystore**
2. Choose `GoogleDriveServiceAccount.jks`, enter the keystore password from Step 3/4
3. Name it **`GoogleDriveServiceAccount`** — this must match the `Certificate_Developer_Name__c` value on the `Google_Drive_Setting.Default` custom metadata record (`force-app/main/default/customMetadata/Google_Drive_Setting.Default.md-meta.xml`). If you name it something else, update that record to match.

## Windows / Git Bash gotchas hit while doing this

- **Path format**: Git Bash auto-translates POSIX-style paths (`/c/Users/...`) for MSYS-aware tools, but this translation doesn't reliably apply to arguments embedded inside a larger string (e.g. inside a `python -c "..."` code string) or to non-MSYS executables. Use plain Windows-style paths with forward slashes (`C:/Users/...`) for anything passed to `python`/`openssl`/`keytool` to sidestep this.
- **`-subj "/CN=..."` gets mangled**: Git Bash's MSYS layer treats any argument starting with `/` as a POSIX path and rewrites it — so `/CN=GoogleDriveServiceAccount` silently turns into something like `C:/Program Files/Git/CN=GoogleDriveServiceAccount`. Set `export MSYS_NO_PATHCONV=1` before running the `openssl req` command to disable this.

## Security notes

- Never commit `private_key.pem`, `keystore.p12`, or the `.jks` file to source control. The private key only belongs in Salesforce's Certificate and Key Management and (temporarily) on disk during this conversion.
- Delete the original downloaded JSON key file once the import succeeds — you won't need it again, and it holds the same private key in plaintext.
- If the key material was ever pasted into a chat, ticket, or log, treat it as compromised and rotate it in Google Cloud Console (delete the old key, create a new one, redo this whole process) — don't rely on it staying secret just because you deleted the message.
