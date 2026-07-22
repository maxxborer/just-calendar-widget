import AppKit
import Foundation

struct SemanticVersion: Comparable, Equatable, Sendable {
    let major: Int
    let minor: Int
    let patch: Int

    var displayString: String {
        "\(major).\(minor).\(patch)"
    }

    init?(tag: String) {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutPrefix = trimmedTag.hasPrefix("v") ? String(trimmedTag.dropFirst()) : trimmedTag
        let stableVersion = withoutPrefix.split(separator: "-", maxSplits: 1).first.map(String.init) ?? withoutPrefix
        let components = stableVersion.split(separator: ".", omittingEmptySubsequences: false)

        guard components.count == 3,
              let major = Int(components[0]),
              let minor = Int(components[1]),
              let patch = Int(components[2]),
              major >= 0,
              minor >= 0,
              patch >= 0
        else {
            return nil
        }

        self.major = major
        self.minor = minor
        self.patch = patch
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}

struct AvailableUpdate: Equatable, Sendable {
    let version: SemanticVersion
    let releaseURL: URL
}

@MainActor
final class UpdateChecker: ObservableObject {
    @Published private(set) var availableUpdate: AvailableUpdate?
    @Published private(set) var isChecking = false
    @Published private(set) var lastCheckedAt: Date?
    @Published private(set) var lastErrorDescription: String?

    private enum Preference {
        static let automaticChecksEnabled = "automatic-update-checks-enabled"
        static let lastCheckedAt = "last-update-check-interval"
    }

    private let defaults: UserDefaults
    private let session: URLSession
    private let releaseURL = URL(string: "https://api.github.com/repos/maxxborer/just-calendar-widget/releases/latest")
    private let weeklyInterval: TimeInterval = 7 * 24 * 60 * 60

    init(defaults: UserDefaults = .standard, session: URLSession = .shared) {
        self.defaults = defaults
        self.session = session
        if defaults.object(forKey: Preference.lastCheckedAt) != nil {
            lastCheckedAt = Date(timeIntervalSince1970: defaults.double(forKey: Preference.lastCheckedAt))
        }
    }

    var automaticChecksEnabled: Bool {
        if defaults.object(forKey: Preference.automaticChecksEnabled) == nil {
            return true
        }
        return defaults.bool(forKey: Preference.automaticChecksEnabled)
    }

    var installedVersion: SemanticVersion? {
        let bundleValue = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        return SemanticVersion(tag: String(describing: bundleValue ?? "0.0.0"))
    }

    func setAutomaticChecksEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: Preference.automaticChecksEnabled)

        if !isEnabled {
            availableUpdate = nil
            lastErrorDescription = nil
        } else {
            checkIfNeeded()
        }
    }

    func checkIfNeeded(now: Date = Date()) {
        guard automaticChecksEnabled,
              !isChecking,
              lastCheckedAt.map({ now.timeIntervalSince($0) >= weeklyInterval }) ?? true
        else {
            return
        }

        startCheck()
    }

    func checkNow() {
        guard !isChecking else {
            return
        }

        startCheck()
    }

    func dismissAvailableUpdate() {
        availableUpdate = nil
    }

    func openAvailableUpdate() {
        guard let availableUpdate else {
            return
        }

        NSWorkspace.shared.open(availableUpdate.releaseURL)
    }

    private func startCheck() {
        guard let releaseURL else {
            return
        }

        isChecking = true
        lastErrorDescription = nil

        Task { [weak self, session] in
            do {
                var request = URLRequest(url: releaseURL)
                request.timeoutInterval = 15
                let (data, _) = try await session.data(for: request)
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                self?.finishCheck(with: release, checkedAt: Date())
            } catch {
                self?.finishCheck(with: error)
            }
        }
    }

    private func finishCheck(with release: GitHubRelease, checkedAt: Date) {
        defer {
            isChecking = false
            lastCheckedAt = checkedAt
            defaults.set(checkedAt.timeIntervalSince1970, forKey: Preference.lastCheckedAt)
        }

        guard let latestVersion = SemanticVersion(tag: release.tagName),
              let installedVersion,
              installedVersion < latestVersion
        else {
            availableUpdate = nil
            return
        }

        availableUpdate = AvailableUpdate(version: latestVersion, releaseURL: release.htmlURL)
    }

    private func finishCheck(with _: Error) {
        isChecking = false
        lastCheckedAt = nil
        defaults.removeObject(forKey: Preference.lastCheckedAt)
        lastErrorDescription = "Couldn’t check for updates. Check your internet connection and try again."
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
