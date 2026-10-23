import CoreText
import AppKit
import SwiftUI

/// Hosts the production widget view at macOS widget sizes, then captures its
/// on-screen window. No calendar markup, drawn mockups, or web replicas.
@main
struct CaptureWidgets {
    @MainActor
    static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let arguments = CommandLine.arguments
        guard arguments.count == 3 else {
            throw CaptureError.arguments
        }
        let output = URL(fileURLWithPath: arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let fontURL = URL(fileURLWithPath: arguments[2])
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_GB")
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.firstWeekday = 2
        guard let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 12)) else {
            throw CaptureError.date
        }

        func entry(_ kind: WidgetKind) -> CalendarEntry {
            CalendarEntry(date: date, kind: kind, grids: kind.monthOffsets.map { offset in
                CalendarGrid.make(
                    for: CalendarGrid.monthDate(from: date, offset: offset, calendar: calendar),
                    referenceDate: date, calendar: calendar
                )
            })
        }

        let two = entry(.twoMonths)
        let four = entry(.fourMonths)
        let current = entry(.currentMonth)
        let gallery = VStack(alignment: .leading, spacing: 16) {
            widget(two, height: 164)
            HStack(alignment: .top, spacing: 16) {
                widget(four, height: 360)
                widget(current, height: 360)
            }
        }
        .padding(24)
        .background(CalendarAppearance.brand)
        .environment(\.locale, Locale(identifier: "en_GB"))
        .environment(\.colorScheme, .light)

        let captures: [(String, AnyView, CGSize)] = [
            ("widgets-macos.png", AnyView(gallery), CGSize(width: 752, height: 588)),
            ("two-months-macos.png", AnyView(widget(two, height: 164)), CGSize(width: 344, height: 164)),
            ("four-months-macos.png", AnyView(widget(four, height: 360)), CGSize(width: 344, height: 360)),
            ("current-month-macos.png", AnyView(widget(current, height: 360)), CGSize(width: 344, height: 360))
        ]

        for (name, view, size) in captures {
            let window = NSWindow(
                contentRect: CGRect(origin: CGPoint(x: 40, y: 40), size: size),
                styleMask: [.borderless], backing: .buffered, defer: false
            )
            window.isReleasedWhenClosed = false
            window.backgroundColor = .clear
            window.isOpaque = false
            window.contentView = NSHostingView(rootView: view.environment(\.colorScheme, .light))
            window.orderFrontRegardless()
            // Give SwiftUI and Canvas time to draw in the actual window server.
            RunLoop.current.run(until: Date().addingTimeInterval(1))
            let capture = Process()
            capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            capture.arguments = ["-x", "-o", "-l", String(window.windowNumber), output.appendingPathComponent(name).path]
            try capture.run()
            capture.waitUntilExit()
            guard capture.terminationStatus == 0 else {
                throw CaptureError.screenshot(name)
            }
            window.close()
        }
    }

    @MainActor
    private static func widget(_ entry: CalendarEntry, height: CGFloat) -> some View {
        CalendarWidgetContent(entry: entry)
            .frame(width: 344, height: height)
            .background(CalendarAppearance.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private enum CaptureError: Error {
        case arguments
        case date
        case screenshot(String)
    }
}
