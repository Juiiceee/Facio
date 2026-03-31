import Foundation

/// Charge les secrets depuis ~/.facio_config (hors du repo)
/// Format du fichier :
///   SUPABASE_URL=https://xxx.supabase.co
///   SUPABASE_ANON_KEY=eyJhbG...
enum Secrets {
    private static let config: [String: String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let configURL = home.appendingPathComponent(".facio_config")
        guard let content = try? String(contentsOf: configURL, encoding: .utf8) else { return [:] }

        var dict: [String: String] = [:]
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            dict[String(parts[0]).trimmingCharacters(in: .whitespaces)] = String(parts[1]).trimmingCharacters(in: .whitespaces)
        }
        return dict
    }()

    static var supabaseURL: String {
        config["SUPABASE_URL"] ?? ""
    }

    static var supabaseAnonKey: String {
        config["SUPABASE_ANON_KEY"] ?? ""
    }
}
