import AppKit
import Combine
import SwiftUI
import WidgetKit

@MainActor
final class WidgetStatus: ObservableObject {
    @Published private(set) var addedKinds: Set<WidgetKind> = []
    @Published private(set) var isLoading = true

    func refresh() {
        WidgetCenter.shared.getCurrentConfigurations { [weak self] result in
            let kinds: Set<WidgetKind>
            switch result {
            case let .success(configurations):
                kinds = Set(configurations.compactMap { WidgetKind(rawValue: $0.kind) })
            case .failure:
                kinds = []
            }

            Task { @MainActor [weak self] in
                self?.addedKinds = kinds
                self?.isLoading = false
            }
        }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var updateChecker: UpdateChecker
    @StateObject private var status = WidgetStatus()
    @State private var currentStep = 0

    var body: some View {
        Group {
            if status.isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if status.addedKinds.isEmpty {
                SetupGuide(currentStep: $currentStep, refresh: reloadWidgets)
            } else {
                WidgetStatusView(
                    addedKinds: status.addedKinds,
                    refresh: reloadWidgets
                )
            }
        }
        .frame(minWidth: 680, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            reloadWidgets()
            updateChecker.checkIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                status.refresh()
                updateChecker.checkIfNeeded()
            }
        }
        .onOpenURL { url in
            if url.scheme == "justcalendarwidget" {
                CalendarApplication.open()
            }
        }
        .alert("A new version is available", isPresented: updateAlertBinding) {
            Button("Open Release") {
                updateChecker.openAvailableUpdate()
                updateChecker.dismissAvailableUpdate()
            }
            Button("Not Now", role: .cancel) {
                updateChecker.dismissAvailableUpdate()
            }
        } message: {
            Text("Just Calendar Widget \(updateChecker.availableUpdate?.version.displayString ?? "") is ready to download.")
        }
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        status.refresh()
    }

    private var updateAlertBinding: Binding<Bool> {
        Binding(
            get: { updateChecker.availableUpdate != nil },
            set: { isPresented in
                if !isPresented {
                    updateChecker.dismissAvailableUpdate()
                }
            }
        )
    }
}

private struct SetupGuide: View {
    @Binding var currentStep: Int
    let refresh: () -> Void

    private let steps = [
        SetupStep(
            icon: "cursorarrow.click.2",
            title: "Open the widget gallery",
            description: "Control-click the desktop, then choose Edit Widgets."
        ),
        SetupStep(
            icon: "magnifyingglass",
            title: "Find Just Calendar Widget",
            description: "Search by name in the widget gallery."
        ),
        SetupStep(
            icon: "rectangle.grid.2x2",
            title: "Choose a layout",
            description: "Add two months, four months, or one large current month."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .symbolRenderingMode(.hierarchical)

                Text("Your calendar belongs on the desktop")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Add a Just Calendar Widget to see your months at a glance.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 44)

            HStack(spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    StepIndicator(step: step, number: index + 1, isCurrent: index == currentStep) {
                        currentStep = index
                    }
                }
            }
            .padding(.top, 34)
            .padding(.horizontal, 36)

            SetupStepDetail(step: steps[currentStep])
                .padding(.top, 24)
                .padding(.horizontal, 36)

            WidgetOptionsPreview()
                .padding(.top, 24)
                .padding(.horizontal, 36)

            HStack {
                Button("Back") {
                    currentStep = max(currentStep - 1, 0)
                }
                .disabled(currentStep == 0)

                Spacer()

                if currentStep < steps.count - 1 {
                    Button("Next") {
                        currentStep += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Check for widgets", systemImage: "arrow.clockwise") {
                        refresh()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(36)
        }
    }
}

private struct WidgetStatusView: View {
    let addedKinds: Set<WidgetKind>
    let refresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Your widgets are ready", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)

                    Text("Just Calendar Widget is active on your desktop.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }

                Button("Refresh", systemImage: "arrow.clockwise") {
                    refresh()
                }
            }

            Text("Added layouts")
                .font(.headline)

            HStack(spacing: 16) {
                ForEach(WidgetKind.allCases, id: \.self) { kind in
                    AddedWidgetCard(kind: kind, isAdded: addedKinds.contains(kind))
                }
            }

            Spacer()

            Text("To add another layout, Control-click the desktop and choose Edit Widgets.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(36)
    }
}

private struct StepIndicator: View {
    let step: SetupStep
    let number: Int
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isCurrent ? Color.accentColor : Color.secondary.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Text(number, format: .number)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isCurrent ? .white : .secondary)
                }

                Text(step.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isCurrent ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Step \(number)"))
    }
}

private struct SetupStepDetail: View {
    let step: SetupStep

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: step.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.headline)
                Text(step.description)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct WidgetOptionsPreview: View {
    var body: some View {
        HStack(spacing: 12) {
            PreviewTile(icon: "rectangle.split.2x1", title: "Two Months", size: "2×1")
            PreviewTile(icon: "rectangle.grid.2x2", title: "Four Months", size: "2×2")
            PreviewTile(icon: "calendar", title: "Current Month", size: "2×2")
        }
    }
}

private struct PreviewTile: View {
    let icon: String
    let title: LocalizedStringKey
    let size: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(size)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AddedWidgetCard: View {
    let kind: WidgetKind
    let isAdded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isAdded ? Color.accentColor : Color.secondary)
            Text(kind.displayName)
                .font(.subheadline.weight(.semibold))
            Label(isAdded ? "Added" : "Not added", systemImage: isAdded ? "checkmark" : "minus")
                .font(.caption)
                .foregroundStyle(isAdded ? Color.accentColor : Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var icon: String {
        switch kind {
        case .twoMonths:
            "rectangle.split.2x1"
        case .fourMonths:
            "rectangle.grid.2x2"
        case .currentMonth:
            "calendar"
        }
    }
}

private struct SetupStep {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

private enum CalendarApplication {
    static func open() {
        guard let calendarURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") else {
            return
        }
        NSWorkspace.shared.openApplication(at: calendarURL, configuration: .init())
    }
}

struct SettingsView: View {
    @ObservedObject var updateChecker: UpdateChecker
    @State private var automaticallyCheckForUpdates: Bool

    init(updateChecker: UpdateChecker) {
        self.updateChecker = updateChecker
        _automaticallyCheckForUpdates = State(initialValue: updateChecker.automaticChecksEnabled)
    }

    var body: some View {
        Form {
            Section("Software Updates") {
                Toggle("Check for updates automatically", isOn: $automaticallyCheckForUpdates)
                    .onChange(of: automaticallyCheckForUpdates) { _, isEnabled in
                        updateChecker.setAutomaticChecksEnabled(isEnabled)
                    }

                Text("When enabled, Just Calendar Widget checks the public GitHub Releases feed at most once every seven days.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack {
                    Button(updateChecker.isChecking ? "Checking…" : "Check Now") {
                        updateChecker.checkNow()
                    }
                    .disabled(updateChecker.isChecking)

                    Spacer()

                    if let lastCheckedAt = updateChecker.lastCheckedAt {
                        Text("Last checked \(lastCheckedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let lastErrorDescription = updateChecker.lastErrorDescription {
                    Text(lastErrorDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 510)
        .padding(20)
    }
}
