import SwiftUI

@main
struct JustCalendarWidgetApp: App {
    @StateObject private var updateChecker = UpdateChecker()

    var body: some Scene {
        WindowGroup {
            ContentView(updateChecker: updateChecker)
        }
        .defaultSize(width: 760, height: 560)
        .windowResizability(.contentSize)

        Settings {
            SettingsView(updateChecker: updateChecker)
        }
    }
}
