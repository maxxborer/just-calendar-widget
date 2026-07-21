# Releasing Just Calendar Widget

## Automatic releases

Every direct push or merged pull request in `main` or `master` starts the **Release on default branch** workflow. It runs tests, raises the patch version, builds the app, commits the new version, creates a tag, and publishes a GitHub Release with generated notes.

For example, a push while the version is `0.1.0` publishes `v0.1.1` and commits that version back to the same branch. The workflow uses a `[skip release]` commit marker to avoid recursively creating another release.

GitHub source archives are created automatically for every Release. The workflow also attaches an installable DMG with the app, an Applications shortcut, a bilingual installation guide, and a custom Finder background. When Apple signing secrets are configured, the workflow signs the app with Developer ID, notarizes the DMG with Apple, staples the resulting ticket, and attaches the final DMG. Without those secrets, it produces an unsigned preview DMG instead.

### Starting a new minor or major line

Run one of these commands locally, review the changed version file, commit it, and push or merge it to `main`/`master`:

```sh
# 0.1.0 → 0.2.0; the following push releases 0.2.1
scripts/version.sh minor

# 0.1.0 → 1.0.0; the following push releases 1.0.1
scripts/version.sh major
```

`scripts/version.sh patch` is available for local maintenance, but normal patch releases are always created by GitHub Actions.

### One-time GitHub setting

If branch protection or a ruleset is enabled, allow **GitHub Actions** to bypass the rule for the release version commit. Otherwise the workflow cannot write its version commit and tag back to the protected branch.

In **Settings → Actions → General**, set **Workflow permissions** to **Read and write permissions**. This allows the workflow's scoped `contents: write` token to create its version commit, tag, and Release.

### Unsigned preview builds

Unsigned builds are useful for early adopters and contributors. macOS may block the first launch; users can approve it in **System Settings → Privacy & Security**. Do not describe an unsigned build as notarized or production-signed.

## Signed and notarized public releases

To remove Gatekeeper's “Apple cannot verify” warning for public downloads, use an Apple Developer Program account and enable the existing App Group for the app identifier. Add these GitHub Actions secrets; the existing workflow switches to Developer ID signing and notarization automatically when all nine are available:

| Secret | Purpose |
| --- | --- |
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded Developer ID Application certificate (`.p12`). |
| `APPLE_CERTIFICATE_PASSWORD` | Password for that certificate. |
| `KEYCHAIN_PASSWORD` | Temporary CI keychain password. |
| `APPLE_API_KEY_BASE64` | Base64-encoded App Store Connect API key (`.p8`). |
| `APPLE_API_KEY_ID` | App Store Connect API key ID. |
| `APPLE_API_ISSUER_ID` | App Store Connect issuer ID. |
| `APPLE_TEAM_ID` | Apple Developer Team ID. |
| `APP_PROVISIONING_PROFILE_BASE64` | Base64-encoded Developer ID profile for `com.justcalendarwidget.app`. |
| `WIDGET_PROVISIONING_PROFILE_BASE64` | Base64-encoded Developer ID profile for `com.justcalendarwidget.app.widgets`. |

The workflow imports the certificate and both Developer ID profiles, signs the app and its widget extension with hardened runtime, builds an installable DMG, submits it through `xcrun notarytool`, staples and validates the ticket, then uploads the notarized DMG to the same Release. Apple Developer membership and these secrets are the only missing inputs; no source-code change is required after adding them.

Before the first public release, make one manual signed build in Xcode or a protected test branch to verify that the App Group entitlement is active for the selected Apple Developer team.
