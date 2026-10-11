import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Model

enum Tool: String, CaseIterable, Identifiable {
    case pen = "Pen"
    case line = "Line"
    case rectangle = "Rectangle"
    case ellipse = "Ellipse"
    case eraser = "Eraser"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pen: return "pencil.tip"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .eraser: return "eraser"
        }
    }
}

struct Stroke {
    var tool: Tool
    var points: [CGPoint]
    var color: Color
    var width: CGFloat
}

final class PaintModel: ObservableObject {
    @Published var strokes: [Stroke] = []
    @Published var redoStack: [Stroke] = []
    @Published var current: Stroke?

    @Published var tool: Tool = .pen
    @Published var color: Color = .black
    @Published var lineWidth: CGFloat = 4
    @Published var background: Color = .white

    func begin(at point: CGPoint) {
        current = Stroke(tool: tool, points: [point], color: color, width: lineWidth)
    }

    func extend(to point: CGPoint) {
        guard current != nil else { return }
        switch tool {
        case .pen, .eraser:
            current?.points.append(point)
        case .line, .rectangle, .ellipse:
            // Shapes only need a start and an end point.
            current?.points = [current!.points[0], point]
        }
    }

    func end() {
        if let stroke = current {
            strokes.append(stroke)
            redoStack.removeAll()
        }
        current = nil
    }

    func undo() {
        guard let last = strokes.popLast() else { return }
        redoStack.append(last)
    }

    func redo() {
        guard let last = redoStack.popLast() else { return }
        strokes.append(last)
    }

    func clear() {
        strokes.removeAll()
        redoStack.removeAll()
    }
}

// MARK: - Drawing

func draw(_ stroke: Stroke, in context: inout GraphicsContext, background: Color) {
    guard let first = stroke.points.first else { return }
    let last = stroke.points.last ?? first
    var path = Path()

    switch stroke.tool {
    case .pen, .eraser:
        if stroke.points.count == 1 {
            // A single click draws a dot.
            let r = stroke.width / 2
            path.addEllipse(in: CGRect(x: first.x - r, y: first.y - r, width: stroke.width, height: stroke.width))
            context.fill(path, with: .color(stroke.tool == .eraser ? background : stroke.color))
            return
        }
        path.addLines(stroke.points)
    case .line:
        path.move(to: first)
        path.addLine(to: last)
    case .rectangle:
        path.addRect(CGRect(from: first, to: last))
    case .ellipse:
        path.addEllipse(in: CGRect(from: first, to: last))
    }

    let color = stroke.tool == .eraser ? background : stroke.color
    context.stroke(path, with: .color(color),
                   style: StrokeStyle(lineWidth: stroke.width, lineCap: .round, lineJoin: .round))
}

extension CGRect {
    init(from a: CGPoint, to b: CGPoint) {
        self.init(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
    }
}

struct CanvasView: View {
    @ObservedObject var model: PaintModel

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(model.background))
            for stroke in model.strokes {
                draw(stroke, in: &context, background: model.background)
            }
            if let current = model.current {
                draw(current, in: &context, background: model.background)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    if model.current == nil {
                        model.begin(at: value.startLocation)
                    }
                    model.extend(to: value.location)
                }
                .onEnded { _ in model.end() }
        )
    }
}

// MARK: - UI

struct ContentView: View {
    @StateObject private var model = PaintModel()
    @State private var canvasSize = CGSize(width: 900, height: 600)

    private let palette: [Color] = [.black, .gray, .red, .orange, .yellow, .green, .blue, .purple, .brown, .white]

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            GeometryReader { geo in
                CanvasView(model: model)
                    .onAppear { canvasSize = geo.size }
                    .onChange(of: geo.size) { canvasSize = $0 }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    private var toolbar: some View {
        HStack(spacing: 14) {
            Picker("Tool", selection: $model.tool) {
                ForEach(Tool.allCases) { tool in
                    Image(systemName: tool.icon).help(tool.rawValue).tag(tool)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 220)

            Divider().frame(height: 22)

            HStack(spacing: 4) {
                ForEach(palette, id: \.self) { c in
                    Circle()
                        .fill(c)
                        .overlay(Circle().stroke(Color.primary.opacity(0.3), lineWidth: 1))
                        .overlay(Circle().stroke(Color.accentColor, lineWidth: model.color == c ? 3 : 0))
                        .frame(width: 20, height: 20)
                        .onTapGesture { model.color = c }
                }
                ColorPicker("", selection: $model.color).labelsHidden()
            }

            Divider().frame(height: 22)

            HStack(spacing: 6) {
                Image(systemName: "scribble")
                Slider(value: $model.lineWidth, in: 1...50).frame(width: 110)
                Text("\(Int(model.lineWidth))").monospacedDigit().frame(width: 24)
            }

            Spacer()

            Button { model.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(model.strokes.isEmpty)
                .help("Undo")
            Button { model.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(model.redoStack.isEmpty)
                .help("Redo")
            Button { model.clear() } label: { Image(systemName: "trash") }
                .help("Clear canvas")
            Button { save() } label: { Image(systemName: "square.and.arrow.down") }
                .keyboardShortcut("s", modifiers: .command)
                .help("Save as PNG")
        }
        .padding(10)
    }

    @MainActor
    private func save() {
        let renderer = ImageRenderer(content: CanvasView(model: model)
            .frame(width: canvasSize.width, height: canvasSize.height))
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        guard let cgImage = renderer.cgImage else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Drawing.png"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let rep = NSBitmapImageRep(cgImage: cgImage)
        if let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: url)
        }
    }
}

// MARK: - App

@main
struct VisualPaintApp: App {
    init() {
        // Needed so a SwiftPM executable shows up as a normal foreground app.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup("Visual Paint") {
            ContentView()
        }
    }
}
