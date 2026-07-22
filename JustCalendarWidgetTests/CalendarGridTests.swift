import XCTest
@testable import Just_Calendar_Widget

final class CalendarGridTests: XCTestCase {
    private var calendar = Calendar(identifier: .gregorian)

    override func setUp() {
        var configuredCalendar = Calendar(identifier: .gregorian)
        configuredCalendar.locale = Locale(identifier: "en_US_POSIX")
        configuredCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        configuredCalendar.firstWeekday = 2
        calendar = configuredCalendar
    }

    func testLeapYearFebruaryContainsTwentyNineDays() throws {
        let grid = CalendarGrid.make(for: try date(year: 2024, month: 2, day: 1), calendar: calendar)

        XCTAssertEqual(grid.weeks.flatMap { $0 }.compactMap { $0 }.count, 29)
        XCTAssertEqual(grid.weeks.count, 5)
    }

    func testMonthOffsetCrossesYearBoundary() throws {
        let december = try date(year: 2025, month: 12, day: 15)
        let january = CalendarGrid.monthDate(from: december, offset: 1, calendar: calendar)
        let components = calendar.dateComponents([.year, .month], from: january)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 1)
    }

    func testWeekdaySymbolsStartWithConfiguredFirstWeekday() throws {
        let grid = CalendarGrid.make(for: try date(year: 2026, month: 7, day: 1), calendar: calendar)

        XCTAssertEqual(grid.weekdaySymbols.first, "M")
        XCTAssertEqual(grid.weekdaySymbols.count, 7)
    }

    func testMonthTitleUsesCalendarLocale() throws {
        let grid = CalendarGrid.make(for: try date(year: 2026, month: 2, day: 1), calendar: calendar)

        XCTAssertEqual(grid.monthTitle, calendar.standaloneMonthSymbols[1].localizedCapitalized)
    }

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        let components = DateComponents(calendar: calendar, year: year, month: month, day: day)
        return try XCTUnwrap(calendar.date(from: components))
    }
}
