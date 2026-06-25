#if DEBUG
import Foundation

/// Stockage de secrets **dev uniquement** (jamais compilé en release).
///
/// Les builds `swift run` ne sont pas signés de façon stable : leur signature
/// change à chaque compilation, donc l'ACL du trousseau ne « colle » jamais et
/// macOS redemande l'autorisation à chaque accès. Pour ne pas subir ces pop-ups
/// en développement, `KeychainService` (tokens d'auth) et `SecurePersistence`
/// (clé de chiffrement locale) routent leur stockage vers ce fichier local 0600
/// en debug. En release, ils utilisent le trousseau normalement.
enum DevSecretStore {
    private static let lock = NSLock()

    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Facio/.dev-secrets.json", isDirectory: false)
    }

    private static func load() -> [String: String] {
        guard let data = try? Data(contentsOf: fileURL),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return dict
    }

    private static func persist(_ dict: [String: String]) {
        let url = fileURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(dict) else { return }
        try? data.write(to: url, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    static func data(for key: String) -> Data? {
        lock.lock(); defer { lock.unlock() }
        return load()[key].flatMap { Data(base64Encoded: $0) }
    }

    static func set(_ data: Data, for key: String) {
        lock.lock(); defer { lock.unlock() }
        var dict = load()
        dict[key] = data.base64EncodedString()
        persist(dict)
    }

    static func delete(_ key: String) {
        lock.lock(); defer { lock.unlock() }
        var dict = load()
        dict.removeValue(forKey: key)
        persist(dict)
    }

    static func deleteAll(withPrefix prefix: String) {
        lock.lock(); defer { lock.unlock() }
        let dict = load().filter { !$0.key.hasPrefix(prefix) }
        persist(dict)
    }
}
#endif
