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
        let sharedOffset = MonthOffsetStore.offset(for: kind)
        let grids = kind.monthOffsets.map { monthOffset in
            CalendarGrid.make(
                for: CalendarGrid.monthDate(from: date, offset: sharedOffset + monthOffset, calendar: calendar),
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
        VStack(spacing: 8) {
            WidgetHeader(kind: entry.kind, title: headerTitle)

            switch entry.kind {
            case .twoMonths:
                HStack(alignment: .top, spacing: 12) {
                    ForEach(entry.grids, id: \.monthStart) { grid in
                        MonthGridView(grid: grid, style: .mini)
                    }
                }
            case .fourMonths:
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 10
                ) {
                    ForEach(entry.grids, id: \.monthStart) { grid in
                        MonthGridView(grid: grid, style: .mini)
                    }
                }
            case .currentMonth:
                if let grid = entry.grids.first {
                    MonthGridView(grid: grid, style: .large)
                }
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var headerTitle: String {
        switch entry.kind {
        case .twoMonths:
            "Calendar"
        case .fourMonths:
            "Calendar overview"
        case .currentMonth:
            entry.grids.first?.title ?? "Calendar"
        }
    }
}

private struct WidgetHeader: View {
    let kind: WidgetKind
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.headline.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 0)

            Button(intent: ChangeMonthIntent(kind: kind, delta: -1)) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous month")

            Button(intent: ChangeMonthIntent(kind: kind, delta: 1)) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next month")
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
    }
}

private enum MonthGridStyle {
    case mini
    case large

    var titleFont: Font {
        switch self {
        case .mini:
            .caption.weight(.semibold)
        case .large:
            .headline.weight(.semibold)
        }
    }

    var dayFont: Font {
        switch self {
        case .mini:
            .caption2
        case .large:
            .callout.weight(.medium)
        }
    }

    var cellHeight: CGFloat {
        switch self {
        case .mini:
            15
        case .large:
            31
        }
    }
}

private struct MonthGridView: View {
    let grid: CalendarGrid
    let style: MonthGridStyle

    var body: some View {
        VStack(spacing: style == .mini ? 3 : 7) {
            Text(grid.title)
                .font(style.titleFont)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                ForEach(Array(grid.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: style == .mini ? 1 : 4) {
                ForEach(Array(grid.weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                            DayCell(day: day, style: style)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
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
                    .frame(height: style.cellHeight)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func label(for day: CalendarDay) -> some View {
        Text(day.number, format: .number)
            .font(style.dayFont)
            .foregroundStyle(day.isToday ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, minHeight: style.cellHeight)
            .background {
                if day.isToday {
                    Capsule().fill(Color.accentColor)
                } else if day.isSelected {
                    Capsule().fill(Color.accentColor.opacity(0.16))
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
