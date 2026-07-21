import AppIntents
import WidgetKit

struct ChangeMonthIntent: AppIntent {
    static let title: LocalizedStringResource = "Change month"
    static let openAppWhenRun = false

    @Parameter(title: "Widget")
    var kind: WidgetKind

    @Parameter(title: "Months")
    var delta: Int

    init() {
        kind = .currentMonth
        delta = 0
    }

    init(kind: WidgetKind, delta: Int) {
        self.kind = kind
        self.delta = delta
    }

    func perform() async throws -> some IntentResult {
        MonthOffsetStore.changeOffset(for: kind, by: delta)
        WidgetCenter.shared.reloadTimelines(ofKind: kind.rawValue)
        return .result()
    }
}
