# Contributing to Just Calendar Widget

Thanks for helping make the calendar calmer and more useful.

## Before you start

- Search existing issues and pull requests to avoid duplicate work.
- For substantial changes, open an issue first and describe the intended user outcome.
- Follow the [Code of Conduct](.github/CODE_OF_CONDUCT.md).

## Local setup

The project requires macOS 14+ and Xcode 16+.

```sh
xcodebuild \
  -project JustCalendarWidget.xcodeproj \
  -scheme JustCalendarWidget \
  -derivedDataPath /tmp/just-calendar-widget-derived \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Use the system calendar, locale, first weekday, colours, and typography. Avoid third-party dependencies unless they solve a clearly documented problem that native Apple frameworks cannot solve.

## Pull requests

1. Create a focused branch from `main`.
2. Keep the change small, accessible, and localized where user-facing copy changes.
3. Add or update tests for calendar logic and state changes.
4. Run the command above before opening the pull request.
5. Complete the pull request template and describe the visible result.

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
