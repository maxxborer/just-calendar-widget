# Releasing Just Calendar Widget

## Automatic unsigned releases

Every direct push or merged pull request in `main` or `master` starts the **Release on default branch** workflow. It runs tests, raises the patch version, builds the app, commits the new version, creates a tag, and publishes a GitHub Release with generated notes.

For example, a push while the version is `0.1.0` publishes `v0.1.1` and commits that version back to the same branch. The workflow uses a `[skip release]` commit marker to avoid recursively creating another release.

GitHub source archives are created automatically for every Release. The project workflow also attaches an unsigned macOS ZIP.

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

Unsigned builds are useful for early adopters and contributors. macOS may block the first launch; users can approve it in **System Settings → Privacy & Security**. Do not describe an unsigned build as notarized or production-signed.

## Recommended public release: signed and notarized

For a smooth public download experience, use an Apple Developer Program account and enable the existing App Group for the app identifier. Before replacing the unsigned workflow, add these GitHub Actions secrets:

| Secret | Purpose |
| --- | --- |
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded Developer ID Application certificate (`.p12`). |
| `APPLE_CERTIFICATE_PASSWORD` | Password for that certificate. |
| `KEYCHAIN_PASSWORD` | Temporary CI keychain password. |
| `APPLE_API_KEY_BASE64` | Base64-encoded App Store Connect API key (`.p8`). |
| `APPLE_API_KEY_ID` | App Store Connect API key ID. |
| `APPLE_API_ISSUER_ID` | App Store Connect issuer ID. |
| `APPLE_TEAM_ID` | Apple Developer Team ID. |

The signing workflow should import the certificate, sign both the app and the widget extension with Developer ID, submit the ZIP with `xcrun notarytool`, staple the notarization ticket, then upload the notarized ZIP to the same release. Keep the unsigned workflow only for preview releases after that migration.
