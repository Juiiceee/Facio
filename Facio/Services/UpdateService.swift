import Foundation

/// Verifie si une nouvelle version est disponible sur GitHub Releases
@Observable
@MainActor
final class UpdateService {
    var latestVersion: String? = nil
    var releaseURL: URL? = nil
    var isChecking = false

    var isUpdateAvailable: Bool {
        guard let latest = latestVersion,
              let current = currentVersion else { return false }
        return compareVersions(latest, isGreaterThan: current)
    }

    private var currentVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    private let repoOwner = "Juiiceee"
    private let repoName = "Facio"

    func checkForUpdates() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let tag = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
            latestVersion = tag
            releaseURL = URL(string: release.htmlURL)
        } catch {
            // Silencieux — pas de connexion ou repo privé
        }
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
