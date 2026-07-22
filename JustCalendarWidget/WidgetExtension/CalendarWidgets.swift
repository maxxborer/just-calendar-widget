import AppKit
import SwiftUI
import WidgetKit

struct CalendarEntry: TimelineEntry {
    let date: Date
    let kind: WidgetKind
    let grids: [CalendarGrid]
}

struct CalendarTimelineProvider: TimelineProvider {
    let kind: WidgetKind

    func placeholder(in context: Context) -> CalendarEntry {
        entry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let now = Date()
        let entry = entry(for: now)
        completion(Timeline(entries: [entry], policy: .after(CalendarGrid.nextMidnight(after: now))))
    }

    private func entry(for date: Date) -> CalendarEntry {
        let calendar = Calendar.autoupdatingCurrent
        let grids = kind.monthOffsets.map { monthOffset in
            CalendarGrid.make(
                for: CalendarGrid.monthDate(from: date, offset: monthOffset, calendar: calendar),
                calendar: calendar
            )
        }
        return CalendarEntry(date: date, kind: kind, grids: grids)
    }
}

struct TwoMonthsCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: WidgetKind.twoMonths.rawValue,
            provider: CalendarTimelineProvider(kind: .twoMonths)
        ) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Two Months")
        .description("The current and next calendar month.")
        .supportedFamilies([.systemMedium])
    }
}

struct FourMonthsCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: WidgetKind.fourMonths.rawValue,
            provider: CalendarTimelineProvider(kind: .fourMonths)
        ) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Four Months")
        .description("The previous, current, and two following calendar months.")
        .supportedFamilies([.systemLarge])
    }
}

struct CurrentMonthCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: WidgetKind.currentMonth.rawValue,
            provider: CalendarTimelineProvider(kind: .currentMonth)
        ) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Current Month")
        .description("A large view of the current calendar month.")
        .supportedFamilies([.systemLarge])
    }
}

struct CalendarWidgetView: View {
    let entry: CalendarEntry

    var body: some View {
        GeometryReader { geometry in
            switch entry.kind {
            case .twoMonths:
                HStack(spacing: 8) {
                    ForEach(entry.grids, id: \.monthStart) { grid in
                        MonthGridView(grid: grid, style: .compact, isPastMonth: isPastMonth(grid))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            case .fourMonths:
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(entry.grids, id: \.monthStart) { grid in
                        MonthGridView(grid: grid, style: .compact, isPastMonth: isPastMonth(grid))
                            .frame(height: (geometry.size.height - 8) / 2)
                    }
                }
            case .currentMonth:
                if let grid = entry.grids.first {
                    MonthGridView(grid: grid, style: .expanded, isPastMonth: false)
                }
            }
        }
        .padding(10)
        .containerBackground(for: .widget) {
            Color(nsColor: .controlBackgroundColor)
        }
    }

    private func isPastMonth(_ grid: CalendarGrid) -> Bool {
        let calendar = Calendar.autoupdatingCurrent
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)) else {
            return false
        }
        return grid.monthStart < currentMonthStart
    }
}

private enum MonthGridStyle {
    case compact
    case expanded

    var weekdayFont: Font {
        switch self {
        case .compact:
            .system(size: 9, weight: .semibold)
        case .expanded:
            .system(size: 12, weight: .semibold)
        }
    }

    var dayFont: Font {
        switch self {
        case .compact:
            .system(size: 12, weight: .medium)
        case .expanded:
            .system(size: 18, weight: .medium)
        }
    }

    var spacing: CGFloat {
        switch self {
        case .compact:
            2
        case .expanded:
            6
        }
    }

    var cornerRadius: CGFloat { self == .compact ? 12 : 18 }

    var padding: CGFloat { self == .compact ? 6 : 14 }
}

private struct MonthGridView: View {
    let grid: CalendarGrid
    let style: MonthGridStyle
    let isPastMonth: Bool

    var body: some View {
        VStack(spacing: style.spacing) {
            HStack(spacing: 0) {
                ForEach(Array(grid.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol.uppercased())
                        .font(style.weekdayFont)
                        .foregroundStyle(Color.accentColor.opacity(0.8))
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: style.spacing) {
                ForEach(Array(grid.weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                            DayCell(day: day, style: style)
                        }
                    }
                }
            }
        }
        .padding(style.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(style == .compact ? 0.045 : 0.03), in: RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .stroke(Color.accentColor.opacity(0.12), lineWidth: 1)
        }
        .opacity(isPastMonth ? 0.56 : 1)
    }
}

private struct DayCell: View {
    let day: CalendarDay?
    let style: MonthGridStyle

    var body: some View {
        Group {
            if let day, let url = DayDeepLink.url(for: day.date) {
                Link(destination: url) {
                    label(for: day)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.date.formatted(date: .complete, time: .omitted))
            } else {
                Color.clear
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func label(for day: CalendarDay) -> some View {
        Text(day.number, format: .number)
            .font(style.dayFont)
            .foregroundStyle(day.isToday ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if day.isToday {
                    Circle().fill(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
    }
}

private enum DayDeepLink {
    static func url(for date: Date) -> URL? {
        URL(string: "justcalendarwidget://day?timestamp=\(date.timeIntervalSince1970)")
    }
}

@main
struct JustCalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        TwoMonthsCalendarWidget()
        FourMonthsCalendarWidget()
        CurrentMonthCalendarWidget()
    }
}
