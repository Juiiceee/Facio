import Foundation

/// Charge les secrets Supabase.
/// Priorite :
/// 1. SecretsGenerated.swift (injecte au build CI, compile dans le binaire)
/// 2. ~/.facio_config (dev local)
enum Secrets {
    static var supabaseURL: String {
        // Valeurs injectees au build CI
        let generated = SecretsGenerated.supabaseURL
        if !generated.isEmpty { return generated }
        // Fallback dev local
        return localConfig["SUPABASE_URL"] ?? ""
    }

    static var supabaseAnonKey: String {
        let generated = SecretsGenerated.supabaseAnonKey
        if !generated.isEmpty { return generated }
        return localConfig["SUPABASE_ANON_KEY"] ?? ""
    }

    // MARK: - Lecture fichier local (dev)

    private static let localConfig: [String: String] = {
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
}
