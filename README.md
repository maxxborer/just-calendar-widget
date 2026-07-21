# Just Calendar Widget

[![CI](https://github.com/maxxborer/just-calendar-widget/actions/workflows/ci.yml/badge.svg)](https://github.com/maxxborer/just-calendar-widget/actions/workflows/ci.yml)
[![MIT License](https://img.shields.io/github/license/maxxborer/just-calendar-widget)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/maxxborer/just-calendar-widget?display_name=tag)](https://github.com/maxxborer/just-calendar-widget/releases)

A focused macOS calendar companion with exactly three desktop widgets. Built with SwiftUI and WidgetKit — no network access, accounts, or third-party dependencies.

[Website](https://maxxborer.github.io/just-calendar-widget/) · [Download](https://github.com/maxxborer/just-calendar-widget/releases) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md)

## Widgets

| Widget | macOS size | Months |
| --- | --- | --- |
| Two Months | Medium (`2×1`) | Current and next |
| Four Months | Large (`2×2`) | Previous, current, and two next |
| Current Month | Large (`2×2`) | One large current month |

The app follows the system calendar, locale, first weekday, and time zone. The current day is accented with the system accent colour. Use the chevrons in a widget to browse months; the selected period is shared by all copies of that widget type.

## Adding a widget

Open **Just Calendar Widget**. If no widget is present, the app displays an interactive three-step guide. On macOS, Control-click the desktop, choose **Edit Widgets**, search for **Just Calendar Widget**, then pick one of the layouts above.

Selecting a date in a widget opens the app and shows the chosen date.

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

## Releases

Every push or merged pull request to `main` or `master` is tested and automatically released as the next patch version. The workflow updates [Config/Version.xcconfig](Config/Version.xcconfig), commits the version, creates a tag, builds an unsigned ZIP, and publishes a GitHub Release.

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
