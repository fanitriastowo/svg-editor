# SVG Editor

A small Flutter desktop app for editing SVG files. Edit the SVG source on the left and see the rendered result update live on the right.

## Features
- Side-by-side text editor and live preview
- Pan and zoom the preview
- Open and save `.svg` files (⌘O / ⌘S)
- Invalid markup shows a message instead of crashing

## Requirements
- Flutter (stable channel) with macOS desktop support
- Xcode

## Run
```sh
flutter pub get
flutter run -d macos
```

## Test
```sh
flutter test
```
