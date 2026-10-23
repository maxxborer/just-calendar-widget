import SwiftUI

@main
struct JustCalendarWidgetApp: App {
    init() {
        CalendarAppearance.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .tint(CalendarAppearance.brand)
        }
        .defaultSize(width: 760, height: 560)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .preferredColorScheme(.light)
                .tint(CalendarAppearance.brand)
        }
    }
}
