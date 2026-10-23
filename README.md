# Just Calendar Widget

[![CI](https://github.com/maxxborer/just-calendar-widget/actions/workflows/ci.yml/badge.svg)](https://github.com/maxxborer/just-calendar-widget/actions/workflows/ci.yml)
[![MIT License](https://img.shields.io/github/license/maxxborer/just-calendar-widget)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/maxxborer/just-calendar-widget?display_name=tag)](https://github.com/maxxborer/just-calendar-widget/releases)

A focused macOS calendar companion with exactly three desktop widgets. Built with SwiftUI and WidgetKit — no accounts, calendar events, or third-party dependencies.

[Website](https://maxxborer.github.io/just-calendar-widget/) · [Download](https://github.com/maxxborer/just-calendar-widget/releases) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md)

## What it is

Just Calendar Widget puts a compact calendar on your desktop. It follows the system calendar, locale, first weekday, and time zone. Each month has a caption; today is highlighted in blue. The visual identity is adapted from [maseaaao.tv](https://github.com/maseaaao/maseaaao.tv): warm light surfaces, #1616D9 accents, and Unbounded month headings. No calendar events are read or stored.

<!-- native-screenshots:start -->
<!-- A macOS capture must exist before adding a product screenshot here. -->
<!-- native-screenshots:end -->

| Widget | macOS size | Months |
| --- | --- | --- |
| Two Months | Medium (`2×1`) | Current and next |
| Four Months | Large (`2×2`) | Previous, current, and two next |
| Current Month | Large (`2×2`) | One large current month |

## Install

1. Download the `.dmg` from the [latest release](https://github.com/maxxborer/just-calendar-widget/releases).
2. Open the disk image and drag **Just Calendar Widget.app** onto **Applications**.
3. Eject the disk image. Do **not** run the app from the DMG.
4. Open **Just Calendar Widget** from Applications once.

The DMG contains the same bilingual installation guide. A file ending in `-adhoc.dmg` is a preview with an ad-hoc signature: it lets macOS register the bundled WidgetKit extension, but it has no Developer ID signature or Apple notarization.

### If macOS blocks the preview

After you try to open the app from Applications, choose **Apple menu → System Settings → Privacy & Security**, scroll to **Security**, and click **Open Anyway** for Just Calendar Widget. Confirm **Open** and authenticate if requested. This creates an exception only for this app; do not disable Gatekeeper globally or use Terminal bypass commands. Apple makes the button available for about one hour after the first launch attempt. Prefer a signed, notarized DMG when one is available.

## Use

Open the app once **from Applications**. If no widget is installed, it shows a three-step guide. Then Control-click the desktop, choose **Edit Widgets**, search for **Just Calendar Widget**, and pick one of the layouts above. WidgetKit registers a widget only after its containing app has been launched at least once after installation.

The two- and four-month layouts show the current period at a glance; the previous month in the four-month layout is intentionally softer. Select a widget to open Calendar.app.

## Updates and privacy

The app does not read your calendar events or send analytics. **Just Calendar Widget → Settings → Check Update** opens the public GitHub Releases page in your browser. There are no automatic update checks.

## Requirements and development

- macOS 14 or newer
- Xcode 16 or newer
- A development team with the `group.com.justcalendarwidget.shared` App Group enabled when signing a local build

Open [JustCalendarWidget.xcodeproj](JustCalendarWidget.xcodeproj) in Xcode, select your development team for both targets, then run the **JustCalendarWidget** scheme.

For a local unsigned verification build:

```sh
xcodebuild \
  -project JustCalendarWidget.xcodeproj \
  -scheme JustCalendarWidget \
  -derivedDataPath /tmp/just-calendar-widget-derived \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Product screenshots

The previous illustrated previews have been removed because they did not match the product. No replacement screenshot is claimed until the native views have actually been captured on macOS.

On macOS, run:

```sh
scripts/capture-screenshots.sh
```

The tool compiles the same `CalendarWidgetContent` used by WidgetKit, hosts it in native windows at medium and large widget sizes, and captures those windows with macOS `screencapture`. Allow Screen Recording for your terminal if macOS requests it. It uses a fixed date (23 October 2026) and English Monday-first calendar for repeatability. The resulting PNG files show actual SwiftUI rendering; they are not captures of installed desktop widgets, so wallpaper, desktop tint, and WidgetKit presentation may differ.

After capturing, run `python3 scripts/publish-screenshots.py` to validate the PNGs and insert them into this README and the website, then commit the images and documentation together. CI also uploads captures as the `widget-screenshots` artifact when GitHub Actions is enabled.

Unbounded is bundled under the [SIL Open Font License](JustCalendarWidget/Resources/Fonts/Unbounded-OFL.txt).

## Releases

Every push or merged pull request to `main` or `master` is tested and automatically released as the next patch version. The workflow updates [Config/Version.xcconfig](Config/Version.xcconfig), commits the version, creates a tag, and publishes a GitHub Release with an installable DMG. If Apple Developer signing secrets are configured, the DMG is Developer ID signed and notarized; otherwise it is an ad-hoc-signed preview so the bundled WidgetKit extension can register.

```sh
# Start the next minor line: 0.1.0 → 0.2.0.
scripts/version.sh minor

# Start the next major line: 0.1.0 → 1.0.0.
scripts/version.sh major
```

The next push after either command produces the following patch release. See [the release guide](docs/releasing.md) for branch-protection requirements and Apple signing/notarization requirements for public production downloads.

## Website

The product website is a dependency-free static site in [`docs/`](docs). The GitHub Pages workflow publishes it at [maxxborer.github.io/just-calendar-widget](https://maxxborer.github.io/just-calendar-widget/) after GitHub Pages is enabled with **Settings → Pages → Source: GitHub Actions**.

After the first push, run **Bootstrap repository labels** once from the repository's **Actions** tab. It creates the labels used by issue forms and generated release notes.

## Community and support

Please read the [contribution guide](CONTRIBUTING.md), [Code of Conduct](.github/CODE_OF_CONDUCT.md), [support policy](SUPPORT.md), and [security policy](SECURITY.md) before opening an issue or pull request.

## License

This project is available under the [MIT License](LICENSE).
