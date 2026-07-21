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
        VStack(spacing: contentSpacing) {
            CalendarWidgetHeader(kind: entry.kind, title: visibleRangeTitle)

            switch entry.kind {
            case .twoMonths:
                HStack(alignment: .top, spacing: 10) {
                    ForEach(entry.grids, id: \.monthStart) { grid in
                        MonthGridView(grid: grid, style: .mini)
                    }
                }
            case .fourMonths:
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
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
        .padding(entry.kind == .currentMonth ? 16 : 14)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(nsColor: .controlBackgroundColor),
                    Color.accentColor.opacity(0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var contentSpacing: CGFloat {
        switch entry.kind {
        case .twoMonths:
            10
        case .fourMonths:
            8
        case .currentMonth:
            14
        }
    }

    private var visibleRangeTitle: String {
        guard let firstGrid = entry.grids.first else {
            return "Calendar"
        }

        guard let lastGrid = entry.grids.last, firstGrid.monthStart != lastGrid.monthStart else {
            return firstGrid.title
        }

        let firstMonth = firstGrid.monthStart.formatted(.dateTime.month(.wide))
        let lastMonth = lastGrid.monthStart.formatted(.dateTime.month(.wide).year())
        return "\(firstMonth) – \(lastMonth)"
    }
}

private struct CalendarWidgetHeader: View {
    let kind: WidgetKind
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("Calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            Button(intent: ChangeMonthIntent(kind: kind, delta: -1)) {
                Image(systemName: "chevron.left")
                    .frame(width: 26, height: 26)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous month")

            Button(intent: ChangeMonthIntent(kind: kind, delta: 1)) {
                Image(systemName: "chevron.right")
                    .frame(width: 26, height: 26)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next month")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.accentColor)
    }
}

private enum MonthGridStyle {
    case mini
    case large

    var titleFont: Font {
        switch self {
        case .mini:
            .caption.weight(.bold)
        case .large:
            .title3.weight(.bold)
        }
    }

    var dayFont: Font {
        switch self {
        case .mini:
            .caption2.weight(.medium)
        case .large:
            .body.weight(.medium)
        }
    }

    var cellHeight: CGFloat {
        switch self {
        case .mini:
            18
        case .large:
            35
        }
    }

    var verticalSpacing: CGFloat {
        switch self {
        case .mini:
            3
        case .large:
            6
        }
    }

    var cardPadding: CGFloat {
        switch self {
        case .mini:
            8
        case .large:
            12
        }
    }
}

private struct MonthGridView: View {
    let grid: CalendarGrid
    let style: MonthGridStyle

    var body: some View {
        VStack(spacing: style.verticalSpacing) {
            HStack(spacing: 6) {
                Text(style == .large ? grid.monthStart.formatted(.dateTime.month(.wide)) : grid.title)
                    .font(style.titleFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if style == .large {
                    Text(grid.monthStart.formatted(.dateTime.year()))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 0) {
                ForEach(Array(grid.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol.uppercased())
                        .font(.system(size: style == .mini ? 8 : 10, weight: .semibold))
                        .foregroundStyle(Color.accentColor.opacity(0.8))
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: style == .mini ? 1 : 5) {
                ForEach(Array(grid.weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                            DayCell(day: day, style: style)
                        }
                    }
                }
            }
        }
        .padding(style.cardPadding)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.primary.opacity(style == .mini ? 0.045 : 0.035), in: RoundedRectangle(cornerRadius: style == .mini ? 12 : 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: style == .mini ? 12 : 16, style: .continuous)
                .stroke(Color.accentColor.opacity(0.12), lineWidth: 1)
        }
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
            .foregroundStyle(day.isToday ? Color.white : day.isSelected ? Color.accentColor : Color.primary)
            .frame(maxWidth: .infinity, minHeight: style.cellHeight)
            .background {
                if day.isToday {
                    Circle().fill(Color.accentColor)
                } else if day.isSelected {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
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
