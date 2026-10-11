# 🎨 Visual Paint

A small, simple paint editor for macOS, written in **Swift** and **SwiftUI**.

The whole app is one Swift file of about 250 lines. You can sketch, draw shapes and export your work as a PNG.

---

## ✨ Features

| | Feature | Details |
|---|---|---|
| ✏️ | **Pen** | Freehand drawing with smooth, rounded strokes |
| 📏 | **Line** | Straight lines with a live preview while you drag |
| ▭ | **Rectangle** | Rectangle outlines drawn by dragging |
| ◯ | **Ellipse** | Ellipse and circle outlines drawn by dragging |
| 🧽 | **Eraser** | Paints over strokes in the background color |
| 🎨 | **Colors** | 10 preset swatches, plus the system color picker for any color |
| 🖌️ | **Brush size** | A slider from 1 to 50 px |
| ↩️ | **Undo / Redo** | Step backward and forward through your strokes |
| 🗑️ | **Clear** | Starts again with an empty canvas |
| 💾 | **Save as PNG** | Exports the canvas at your screen's Retina resolution |

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| <kbd>⌘</kbd> <kbd>Z</kbd> | Undo |
| <kbd>⇧</kbd> <kbd>⌘</kbd> <kbd>Z</kbd> | Redo |
| <kbd>⌘</kbd> <kbd>S</kbd> | Save as PNG |

---

## 🚀 Getting Started

### Requirements

- **macOS 13 Ventura** or later
- **Swift 5.8+**, from the Xcode Command Line Tools (`xcode-select --install`) or full Xcode

### Run it

```sh
./run.sh
```

The script compiles the app with `swiftc` into `.build/VisualPaint` and opens it.

### Other ways to run it

With full Xcode installed, Swift Package Manager works too:

```sh
swift run
```

You can also open `Package.swift` in Xcode and press <kbd>⌘</kbd> <kbd>R</kbd>.

> **Note:** With only the Command Line Tools installed, `swift build` can fail with
> `xcrun: error: unable to lookup item 'PlatformPath'`. This is a known toolchain issue.
> `run.sh` avoids it by calling the compiler directly.

---

## 🗂️ Project Structure

```
visual-paint/
├── Package.swift                         # Swift package definition (macOS 13+)
├── run.sh                                # Build-and-launch script
├── Sources/
│   └── VisualPaint/
│       └── VisualPaintApp.swift          # The entire app
├── .gitignore
└── README.md
```

---

## 🧠 How It Works

The app is split into four parts, marked with `// MARK:` comments in `VisualPaintApp.swift`.

### 1. Model
- **`Tool`** is an enum that lists each drawing tool and its SF Symbol icon.
- **`Stroke`** is one drawn item. It stores its tool, points, color and width.
- **`PaintModel`** is an `ObservableObject`. It holds the finished strokes, the stroke being drawn, the redo stack and the current tool settings.

### 2. Drawing
- `draw(_:in:background:)` turns a `Stroke` into a SwiftUI `Path` and draws it into a `GraphicsContext`.
- The pen and eraser keep every point they pass through. Shapes keep only a start point and an end point.

### 3. Canvas
- **`CanvasView`** uses SwiftUI's `Canvas` to redraw every stroke.
- A `DragGesture` sends mouse input to the model through three steps: **begin**, **extend** and **end**.

### 4. UI and App
- **`ContentView`** shows the toolbar above the canvas and saves PNGs using `ImageRenderer` and `NSSavePanel`.
- **`VisualPaintApp`** is the `@main` entry point. It sets the app's activation policy so it runs as a normal foreground app with a Dock icon when launched from the terminal.

### Undo and redo

Each finished stroke goes on the `strokes` array.

- **Undo** moves the last stroke from `strokes` to `redoStack`.
- **Redo** moves it back.
- Drawing a new stroke empties `redoStack`, as most editors do.

---

## 🛣️ Ideas for the Future

- [ ] Filled shapes, with a fill / outline toggle
- [ ] A paint bucket (flood fill) tool
- [ ] Opening and editing existing images
- [ ] A real eraser that leaves transparent pixels
- [ ] Zoom and pan
- [ ] Layers

---

## 📄 License

This project is free to use, change and learn from.
