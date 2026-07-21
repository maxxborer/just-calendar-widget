import Foundation

enum MonthOffsetStore {
    private static let suiteName = "group.com.justcalendarwidget.shared"
    private static let keyPrefix = "month-offset."
    private static let allowedRange = -120...120

    static func offset(for kind: WidgetKind) -> Int {
        let value = defaults.integer(forKey: key(for: kind))
        return min(max(value, allowedRange.lowerBound), allowedRange.upperBound)
    }

    static func changeOffset(for kind: WidgetKind, by delta: Int) {
        let updatedValue = offset(for: kind) + delta
        defaults.set(
            min(max(updatedValue, allowedRange.lowerBound), allowedRange.upperBound),
            forKey: key(for: kind)
        )
    }

    static func resetOffset(for kind: WidgetKind) {
        defaults.removeObject(forKey: key(for: kind))
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    private static func key(for kind: WidgetKind) -> String {
        keyPrefix + kind.rawValue
    }
}

