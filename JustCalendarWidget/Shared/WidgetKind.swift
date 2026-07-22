import Foundation

enum WidgetKind: String, CaseIterable, Sendable {
    case twoMonths = "JustCalendarWidget.twoMonths"
    case fourMonths = "JustCalendarWidget.fourMonths"
    case currentMonth = "JustCalendarWidget.currentMonth"

    var displayName: LocalizedStringResource {
        switch self {
        case .twoMonths:
            "Two Months"
        case .fourMonths:
            "Four Months"
        case .currentMonth:
            "Current Month"
        }
    }

    var monthOffsets: [Int] {
        switch self {
        case .twoMonths:
            [0, 1]
        case .fourMonths:
            [-1, 0, 1, 2]
        case .currentMonth:
            [0]
        }
    }
}
