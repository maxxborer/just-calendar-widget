import XCTest
@testable import Just_Calendar_Widget

final class MonthOffsetStoreTests: XCTestCase {
    override func setUp() {
        WidgetKind.allCases.forEach { MonthOffsetStore.resetOffset(for: $0) }
    }

    override func tearDown() {
        WidgetKind.allCases.forEach { MonthOffsetStore.resetOffset(for: $0) }
    }

    func testOffsetsAreIndependentForEachWidgetKind() {
        MonthOffsetStore.changeOffset(for: .twoMonths, by: 2)
        MonthOffsetStore.changeOffset(for: .fourMonths, by: -1)

        XCTAssertEqual(MonthOffsetStore.offset(for: .twoMonths), 2)
        XCTAssertEqual(MonthOffsetStore.offset(for: .fourMonths), -1)
        XCTAssertEqual(MonthOffsetStore.offset(for: .currentMonth), 0)
    }

    func testResetReturnsToCurrentMonth() {
        MonthOffsetStore.changeOffset(for: .currentMonth, by: 8)
        MonthOffsetStore.resetOffset(for: .currentMonth)

        XCTAssertEqual(MonthOffsetStore.offset(for: .currentMonth), 0)
    }
}
