# Changelog

All notable changes to this project are documented here.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- A system-style blue calendar redesign for all three widget layouts.
- A generated macOS application icon in the AppIcon asset catalog.
- Weekly GitHub Releases update checks with a user-controlled opt-out and manual check.
- Optional Developer ID signing and Apple notarization in the release workflow.
- Installable DMG releases with an Applications shortcut, bilingual guide, and custom Finder background.
- Ad-hoc signing for preview DMGs so the bundled WidgetKit extension can register without an Apple Developer membership.
- A calendar widget preview and explicit Gatekeeper instructions in the README and installer guide.

## [0.1.0] - 2026-07-21

### Added

- Three native macOS calendar widgets: two months, four months, and a large current month.
- Interactive setup guide for adding the first widget.
- Per-widget-kind month navigation and date deep links.

[Unreleased]: https://github.com/maxxborer/just-calendar-widget/compare/v0.1.1...HEAD
[0.1.0]: https://github.com/maxxborer/just-calendar-widget/releases/tag/v0.1.0
