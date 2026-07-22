import Foundation

struct CalendarDay: Identifiable, Equatable, Sendable {
    let date: Date
    let number: Int
    let isToday: Bool

    var id: Date { date }
}

struct CalendarGrid: Equatable, Sendable {
    let monthStart: Date
    let weekdaySymbols: [String]
    let weeks: [[CalendarDay?]]

    static func make(
        for date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> CalendarGrid {
        let monthComponents = calendar.dateComponents([.year, .month], from: date)
        guard let monthStart = calendar.date(from: monthComponents),
              let dayRange = calendar.range(of: .day, in: .month, for: monthStart),
              let weekday = calendar.dateComponents([.weekday], from: monthStart).weekday
        else {
            return CalendarGrid(
                monthStart: date,
                weekdaySymbols: weekdaySymbols(for: calendar),
                weeks: []
            )
        }

        let leadingEmptyDays = (weekday - calendar.firstWeekday + 7) % 7
        let numberOfSlots = ((leadingEmptyDays + dayRange.count + 6) / 7) * 7
        let days = (0 ..< numberOfSlots).map { slot -> CalendarDay? in
            let dayNumber = slot - leadingEmptyDays + 1
            guard dayRange.contains(dayNumber),
                  let dayDate = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthStart)
            else {
                return nil
            }

            return CalendarDay(
                date: dayDate,
                number: dayNumber,
                isToday: calendar.isDateInToday(dayDate)
            )
        }

        let weeks = stride(from: 0, to: days.count, by: 7).map { index in
            Array(days[index ..< min(index + 7, days.count)])
        }

        return CalendarGrid(
            monthStart: monthStart,
            weekdaySymbols: weekdaySymbols(for: calendar),
            weeks: weeks
        )
    }

    static func monthDate(
        from date: Date,
        offset: Int,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date {
        calendar.date(byAdding: .month, value: offset, to: date) ?? date
    }

    static func nextMidnight(after date: Date, calendar: Calendar = .autoupdatingCurrent) -> Date {
        calendar.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(86_400)
    }

    private static func weekdaySymbols(for calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        guard !symbols.isEmpty else {
            return []
        }
        let firstIndex = max(calendar.firstWeekday - 1, 0)
        return (0 ..< 7).compactMap { index in
            symbols[safe: (firstIndex + index) % symbols.count]
        }
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
