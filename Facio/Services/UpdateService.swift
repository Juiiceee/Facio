import Foundation

enum UpdateCheckResult {
    case notChecked
    case checking
    case updateAvailable
    case upToDate
    case unavailable
    case failed
}

/// Verifie si une nouvelle version est disponible sur GitHub Releases
@Observable
@MainActor
final class UpdateService {
    var latestVersion: String? = nil
    var releaseURL: URL? = nil
    var isChecking = false
    var checkResult: UpdateCheckResult = .notChecked

    var isUpdateAvailable: Bool {
        checkResult == .updateAvailable
    }

    private var currentVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    private let repoOwner = "Juiiceee"
    private let repoName = "Facio"

    func checkForUpdates() async {
        guard !isChecking else { return }
        isChecking = true
        checkResult = .checking
        latestVersion = nil
        releaseURL = nil
        defer { isChecking = false }

        let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                checkResult = .failed
                return
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                checkResult = httpResponse.statusCode == 404 ? .unavailable : .failed
                return
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            // Extrait le semver depuis un tag comme "Facio-v1.8.0" ou "v1.8.0" ou "1.8.0"
            guard let semver = semanticVersion(in: release.tagName) else {
                checkResult = .unavailable
                return
            }

            guard let currentVersion,
                  let currentSemver = semanticVersion(in: currentVersion) else {
                latestVersion = semver
                releaseURL = URL(string: release.htmlURL)
                checkResult = .unavailable
                return
            }

            latestVersion = semver
            releaseURL = URL(string: release.htmlURL)
            checkResult = compareVersions(semver, isGreaterThan: currentSemver) ? .updateAvailable : .upToDate
        } catch {
            checkResult = .failed
        }
    }

    private func semanticVersion(in value: String) -> String? {
        guard let range = value.range(of: #"\d+(?:\.\d+){1,2}"#, options: .regularExpression) else {
            return nil
        }
        return String(value[range])
    }

    /// Compare deux versions semver. Renvoie true si a > b.
    private func compareVersions(_ a: String, isGreaterThan b: String) -> Bool {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }
        let maxLen = max(aParts.count, bParts.count)
        for i in 0..<maxLen {
            let av = i < aParts.count ? aParts[i] : 0
            let bv = i < bParts.count ? bParts[i] : 0
            if av != bv { return av > bv }
        }
        return false
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
