import AppKit
import SwiftUI
import WidgetKit

struct CalendarEntry: TimelineEntry {
    let date: Date
    let kind: WidgetKind
    let grids: [CalendarGrid]
}

struct CalendarTimelineProvider: @MainActor TimelineProvider {
    let kind: WidgetKind

    @MainActor
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntryCache.shared.entry(for: Date(), kind: kind)
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(CalendarEntryCache.shared.entry(for: Date(), kind: kind))
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let now = Date()
        let entry = CalendarEntryCache.shared.entry(for: now, kind: kind)
        completion(Timeline(entries: [entry], policy: .after(CalendarEntryCache.nextHour(after: now))))
    }
}

private enum CalendarEntryFactory {
    static func make(for date: Date, kind: WidgetKind) -> CalendarEntry {
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

@MainActor
private final class CalendarEntryCache {
    static let shared = CalendarEntryCache()

    private var entries: [CacheKey: CalendarEntry] = [:]

    func entry(for date: Date, kind: WidgetKind) -> CalendarEntry {
        let key = CacheKey(date: date, kind: kind)
        if let cachedEntry = entries[key] {
            return cachedEntry
        }

        entries = entries.filter { $0.key.hour == key.hour }
        let entry = CalendarEntryFactory.make(for: date, kind: kind)
        entries[key] = entry
        return entry
    }

    static func nextHour(after date: Date) -> Date {
        Calendar.autoupdatingCurrent.nextDate(
            after: date,
            matching: DateComponents(minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(3_600)
    }

    private struct CacheKey: Hashable {
        let kind: String
        let hour: Int
        let firstWeekday: Int
        let localeIdentifier: String
        let timeZoneIdentifier: String

        init(date: Date, kind: WidgetKind) {
            let calendar = Calendar.autoupdatingCurrent
            self.kind = kind.rawValue
            hour = Int(date.timeIntervalSince1970 / 3_600)
            firstWeekday = calendar.firstWeekday
            localeIdentifier = calendar.locale?.identifier ?? ""
            timeZoneIdentifier = calendar.timeZone.identifier
        }
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
        .contentMarginsDisabled()
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
        .contentMarginsDisabled()
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
        .contentMarginsDisabled()
    }
}

struct CalendarWidgetView: View {
    let entry: CalendarEntry

    var body: some View {
        Group {
            switch entry.kind {
            case .twoMonths:
                EqualGridLayout(columns: 2, rows: 1, spacing: 8) {
                    ForEach(entry.grids, id: \.monthStart) { grid in
                        MonthGridView(grid: grid, style: .compact, isPastMonth: isPastMonth(grid))
                    }
                }
            case .fourMonths:
                EqualGridLayout(columns: 2, rows: 2, spacing: 8) {
                    ForEach(entry.grids, id: \.monthStart) { grid in
                        MonthGridView(grid: grid, style: .compact, isPastMonth: isPastMonth(grid))
                    }
                }
            case .currentMonth:
                if let grid = entry.grids.first {
                    MonthGridView(grid: grid, style: .expanded, isPastMonth: false)
                }
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(CalendarDeepLink.url)
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

private struct EqualGridLayout: Layout {
    let columns: Int
    let rows: Int
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let fallbackWidth = 220 * CGFloat(columns) + spacing * CGFloat(columns - 1)
        let fallbackHeight = 180 * CGFloat(rows) + spacing * CGFloat(rows - 1)
        return CGSize(
            width: proposal.width ?? fallbackWidth,
            height: proposal.height ?? fallbackHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let cellWidth = (bounds.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let cellHeight = (bounds.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)

        for index in subviews.indices {
            let row = index / columns
            let column = index % columns
            let origin = CGPoint(
                x: bounds.minX + CGFloat(column) * (cellWidth + spacing),
                y: bounds.minY + CGFloat(row) * (cellHeight + spacing)
            )
            subviews[index].place(
                at: origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(width: cellWidth, height: cellHeight)
            )
        }
    }
}

private enum MonthGridStyle {
    case compact
    case expanded

    var weekdayFont: Font {
        switch self {
        case .compact:
            .system(size: 11, weight: .semibold)
        case .expanded:
            .system(size: 12, weight: .semibold)
        }
    }

    var dayFont: Font {
        switch self {
        case .compact:
            .system(size: 13, weight: .medium)
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

    var monthTitleFont: Font {
        switch self {
        case .compact:
            .system(size: 13, weight: .semibold)
        case .expanded:
            .system(size: 20, weight: .semibold)
        }
    }

    var cornerRadius: CGFloat { self == .compact ? 24 : 28 }

    var padding: CGFloat { self == .compact ? 4 : 8 }

    var weekdayHeight: CGFloat { self == .compact ? 14 : 16 }

    var monthTitleSpacing: CGFloat { self == .compact ? 2 : 6 }

    var todayDiameterScale: CGFloat { self == .compact ? 0.9 : 0.94 }
}

private struct MonthGridView: View {
    let grid: CalendarGrid
    let style: MonthGridStyle
    let isPastMonth: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: style.monthTitleSpacing) {
            Text(grid.monthTitle)
                .font(style.monthTitleFont)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

            CalendarMonthCanvas(grid: grid, style: style)
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

private struct CalendarMonthCanvas: View {
    let grid: CalendarGrid
    let style: MonthGridStyle

    var body: some View {
        Canvas { context, size in
            guard size.width > 0, size.height > 0 else {
                return
            }

            let columnWidth = size.width / 7
            let weekdayHeight = min(style.weekdayHeight, size.height)
            let gridTop = weekdayHeight + style.spacing
            let rowHeight = max((size.height - gridTop) / 6, 0)

            for index in grid.weekdaySymbols.indices {
                let label = Text(grid.weekdaySymbols[index].uppercased())
                    .font(style.weekdayFont)
                    .foregroundStyle(Color.accentColor.opacity(0.8))
                context.draw(
                    context.resolve(label),
                    at: CGPoint(x: columnWidth * (CGFloat(index) + 0.5), y: weekdayHeight / 2)
                )
            }

            for weekIndex in grid.weeks.indices {
                let week = grid.weeks[weekIndex]
                for dayIndex in week.indices {
                    guard let day = week[dayIndex] else {
                        continue
                    }

                    let center = CGPoint(
                        x: columnWidth * (CGFloat(dayIndex) + 0.5),
                        y: gridTop + rowHeight * (CGFloat(weekIndex) + 0.5)
                    )

                    if day.isToday {
                        let diameter = min(columnWidth, rowHeight) * style.todayDiameterScale
                        let circle = CGRect(
                            x: center.x - diameter / 2,
                            y: center.y - diameter / 2,
                            width: diameter,
                            height: diameter
                        )
                        context.fill(Path(ellipseIn: circle), with: .color(.accentColor))
                    }

                    let label = Text("\(day.number)")
                        .font(style.dayFont)
                        .foregroundStyle(day.isToday ? Color.white : Color.primary)
                    context.draw(context.resolve(label), at: center)
                }
            }
        }
        .accessibilityLabel("Calendar")
    }
}

private enum CalendarDeepLink {
    static let url = URL(string: "justcalendarwidget://calendar")
}

@main
struct JustCalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        TwoMonthsCalendarWidget()
        FourMonthsCalendarWidget()
        CurrentMonthCalendarWidget()
    }
}
