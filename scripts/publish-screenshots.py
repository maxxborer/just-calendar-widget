#!/usr/bin/env python3
"""Publish only native PNG captures already generated on macOS."""
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parent.parent
IMAGES = ROOT / 'docs/images'
SIZES = {
    'widgets-macos.png': (752, 588),
    'two-months-macos.png': (344, 164),
    'four-months-macos.png': (344, 360),
    'current-month-macos.png': (344, 360),
}


def replace_block(text, marker, content):
    start = f'<!-- {marker}:start -->'
    end = f'<!-- {marker}:end -->'
    before, remainder = text.split(start, 1)
    _, after = remainder.split(end, 1)
    return f'{before}{start}\n{content}\n{end}{after}'


def main():
    # Validate every file before modifying either document. Accept 1x and Retina.
    for name, (width, height) in SIZES.items():
        data = (IMAGES / name).read_bytes()
        if data[:8] != b'\x89PNG\r\n\x1a\n' or data[12:16] != b'IHDR':
            raise ValueError(f'{name} is not a PNG capture')
        actual = struct.unpack('>II', data[16:24])
        if actual not in [(width, height), (width * 2, height * 2)]:
            raise ValueError(f'{name} has unexpected dimensions: {actual}')

    readme_path = ROOT / 'README.md'
    site_path = ROOT / 'docs/index.html'
    readme = replace_block(readme_path.read_text(), 'native-screenshots',
        '![Native calendar views captured on macOS](docs/images/widgets-macos.png)\n\n'
        'Production SwiftUI views captured in macOS windows at widget sizes. '
        'Desktop tint and wallpaper effects are controlled by macOS.')
    site = replace_block(site_path.read_text(), 'native-gallery', '''        <figure class="product-preview">
          <img src="images/widgets-macos.png" width="752" height="588" alt="Native macOS capture of all three calendar layouts" />
          <figcaption>Actual SwiftUI views captured on macOS at desktop widget sizes.<br />Desktop tint and wallpaper effects are controlled by macOS.</figcaption>
        </figure>''')
    for marker, filename, width, height, label in [
        ('two', 'two-months-macos.png', 344, 164, 'Two Months widget'),
        ('four', 'four-months-macos.png', 344, 360, 'Four Months widget'),
        ('current', 'current-month-macos.png', 344, 360, 'Current Month widget'),
    ]:
        site = replace_block(site, f'native-{marker}',
            f'            <div class="option-image"><img src="images/{filename}" '
            f'width="{width}" height="{height}" loading="lazy" alt="{label}" /></div>')
    readme_path.write_text(readme)
    site_path.write_text(site)


if __name__ == '__main__':
    main()
