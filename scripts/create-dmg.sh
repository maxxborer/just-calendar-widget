#!/bin/zsh

set -euo pipefail

if (( $# != 2 )); then
  print -u2 "Usage: $0 <Just Calendar Widget.app> <output.dmg>"
  exit 64
fi

app_path="${1:A}"
output_path="${2:A}"
project_root="${0:A:h:h}"
background_path="$project_root/Distribution/DMG/.background/background.png"
instructions_path="$project_root/Distribution/DMG/How to Install.txt"
volume_name="Just Calendar Widget"
app_name="Just Calendar Widget.app"

if [[ ! -d "$app_path" ]]; then
  print -u2 "App bundle not found: $app_path"
  exit 66
fi

if [[ ! -f "$background_path" || ! -f "$instructions_path" ]]; then
  print -u2 "DMG template assets are missing."
  exit 66
fi

if [[ "${app_path:t}" != "$app_name" ]]; then
  print -u2 "Expected app bundle named $app_name, got ${app_path:t}."
  exit 64
fi

work_path="$(mktemp -d "${TMPDIR:-/tmp}/just-calendar-widget-dmg.XXXXXX")"
rw_dmg="$work_path/writable.dmg"
mount_path=""
device=""

cleanup() {
  if [[ -n "$device" ]]; then
    hdiutil detach "$device" -quiet || true
  fi
  rm -rf "$work_path"
}
trap cleanup EXIT

mkdir -p "${output_path:h}"
hdiutil create \
  -size 32m \
  -fs HFS+ \
  -volname "$volume_name" \
  -ov \
  "$rw_dmg" >/dev/null

attach_output="$(hdiutil attach "$rw_dmg" -noverify -noautoopen)"
device="$(print -r -- "$attach_output" | awk '/^\/dev\// { print $1; exit }')"
mount_path="$(print -r -- "$attach_output" | awk -F '\t' '$NF ~ /^\/Volumes\// { path = $NF } END { print path }')"
if [[ -z "$device" || -z "$mount_path" ]]; then
  print -u2 "Could not mount the writable disk image."
  exit 74
fi

ditto "$app_path" "$mount_path/$app_name"
ln -s /Applications "$mount_path/Applications"
ditto "$instructions_path" "$mount_path/How to Install.txt"
mkdir -p "$mount_path/.background"
ditto "$background_path" "$mount_path/.background/background.png"
SetFile -a V "$mount_path/.background"

/usr/bin/osascript <<'APPLESCRIPT'
tell application "Finder"
  tell disk "Just Calendar Widget"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {120, 120, 1020, 660}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 96
    set text size of theViewOptions to 13
    set background picture of theViewOptions to file ".background:background.png"
    set position of item "Just Calendar Widget.app" of container window to {190, 270}
    set position of item "Applications" of container window to {710, 270}
    set position of item "How to Install.txt" of container window to {450, 455}
    close
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$device" -quiet
device=""
hdiutil convert "$rw_dmg" -format UDZO -imagekey zlib-level=9 -ov -o "$output_path" >/dev/null
