# CC2PDF

A single-window macOS SwiftUI app that converts WebVTT closed-caption files (`.vtt`) into PDF.

## Features

- Drag-and-drop one or more VTT files directly into the window.
- Checkbox to remove metadata (`sequence`, `timestamps`, and formatting tags like `<b>`) with removal enabled by default.
- `Convert` writes output PDF in the same directory as the first source file.
- Multi-file drop combines all files into one multi-page PDF.
- Embedded custom app icon set at launch.

## Requirements

- macOS 14+
- Xcode 15+ or Swift 5.9+

## Build

```bash
swift build
```

## Test

```bash
swift test
```

## Run

```bash
swift run CC2PDF
```

## Build as double-clickable .app

`make_app.sh` produces a fully self-contained, ad-hoc-signed `CC2PDF.app` in `dist/`:

```bash
./make_app.sh
open dist/CC2PDF.app
```

The script:
1. Compiles a release binary with `swift build -c release`
2. Renders the icon to a 1024×1024 PNG via `Tools/make_icon.swift`
3. Converts the PNG into a multi-resolution `.icns` using `sips` + `iconutil`
4. Assembles `dist/CC2PDF.app` with the correct `Info.plist`
5. Ad-hoc signs the bundle with `codesign --force --deep --sign -`

To install to `/Applications`:

```bash
./make_app.sh && cp -R dist/CC2PDF.app /Applications/CC2PDF.app
```

> `dist/` is gitignored — it is a build artifact only.

## Usage

1. Launch the app.
2. Drag one or more `.vtt` files into the drop zone, or click `Choose…`.
3. Leave `Remove metadata...` checked (default) if you want clean caption text.
4. Click `Convert`.

Output is written next to the first selected source file using the same base name and `.pdf` extension.
