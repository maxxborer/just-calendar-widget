import SwiftUI

@main
struct JustCalendarWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 760, height: 560)
        .windowResizability(.contentSize)
    }
}

