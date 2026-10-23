#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output="${1:-docs/images}"
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT
xcrun swiftc -swift-version 6 -parse-as-library -D SCREENSHOT \
  JustCalendarWidget/Shared/CalendarAppearance.swift \
  JustCalendarWidget/Shared/CalendarGrid.swift \
  JustCalendarWidget/Shared/WidgetKind.swift \
  JustCalendarWidget/WidgetExtension/CalendarWidgets.swift \
  scripts/screenshots/CaptureWidgets.swift \
  -o "$build_dir/capture-widgets"
"$build_dir/capture-widgets" "$output" JustCalendarWidget/Resources/Fonts/Unbounded.ttf
