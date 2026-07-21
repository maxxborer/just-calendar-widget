# Just Calendar Widget

A focused macOS calendar companion with exactly three desktop widgets. Built with SwiftUI and WidgetKit — no network access, accounts, or third-party dependencies.

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

## License

This project is available under the [MIT License](LICENSE).
