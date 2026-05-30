import CryptoKit
import Foundation
import Security

/// Authenticated local persistence for app data files.
///
/// Data files remain in Application Support for compatibility with sync and backup flows, but their
/// JSON payload is encrypted and authenticated with a per-install AES-GCM key stored in the user's
/// Keychain. Legacy plaintext JSON can still be read until each file is successfully rewritten in
/// the encrypted format on a load/save.
enum SecurePersistence {
    struct PersistedValue<T> {
        let value: T
        let wasLegacyPlaintext: Bool
    }

    private struct Envelope: Codable {
        let format: String
        let algorithm: String
        let combinedSealedBox: String
    }

    private struct MigrationState: Codable {
        var completedFiles: Set<String> = []
    }

    private enum Constants {
        static let format = "com.facio.secure-persistence.v1"
        static let algorithm = "AES.GCM.256"
        static let keychainService = "com.facio.persistence"
        static let keychainAccount = "localDataKey.v1"
        static let keyByteCount = 32
        static let migrationStateFileName = ".secure-persistence-migration.json"
    }

    enum SecurePersistenceError: LocalizedError {
        case invalidKeychainData
        case invalidEncryptedPayload
        case keychainStatus(OSStatus)

        var errorDescription: String? {
            switch self {
            case .invalidKeychainData:
                "The local data encryption key is invalid."
            case .invalidEncryptedPayload:
                "The local data file failed its authenticity check."
            case .keychainStatus(let status):
                "Keychain operation failed with status \(status)."
            }
        }
    }

    static func ensureStorageDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
    }

    static func hardenFile(at url: URL) throws {
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    static func canReadLegacyPlaintext(at url: URL) -> Bool {
        do {
            return try !migrationState(for: url).completedFiles.contains(migrationFileIdentifier(for: url))
        } catch {
            return false
        }
    }

    static func markLegacyPlaintextMigrationCompleted(at url: URL) throws {
        var state = try migrationState(for: url)
        state.completedFiles.insert(migrationFileIdentifier(for: url))
        try saveMigrationState(state, for: url)
    }

    static func decode<T: Decodable>(
        _ type: T.Type,
        from url: URL,
        using decoder: JSONDecoder,
        allowLegacyPlaintext: Bool
    ) throws -> PersistedValue<T> {
        let data = try Data(contentsOf: url)
        if let envelope = try? decoder.decode(Envelope.self, from: data), envelope.format == Constants.format {
            guard envelope.algorithm == Constants.algorithm,
                  let decrypted = try decrypt(envelope: envelope) else {
                throw SecurePersistenceError.invalidEncryptedPayload
            }
            return PersistedValue(value: try decoder.decode(type, from: decrypted), wasLegacyPlaintext: false)
        }

        guard allowLegacyPlaintext else {
            throw SecurePersistenceError.invalidEncryptedPayload
        }
        return PersistedValue(value: try decoder.decode(type, from: data), wasLegacyPlaintext: true)
    }

    static func encode<T: Encodable>(_ value: T, to url: URL, using encoder: JSONEncoder) throws {
        try ensureStorageDirectory(at: url.deletingLastPathComponent())
        let plaintext = try encoder.encode(value)
        let envelope = try encrypt(plaintext)
        let data = try encoder.encode(envelope)
        try data.write(to: url, options: .atomic)
        try hardenFile(at: url)
    }

    static func decodeData(from url: URL) throws -> Data {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(Envelope.self, from: data), envelope.format == Constants.format {
            guard envelope.algorithm == Constants.algorithm,
                  let decrypted = try decrypt(envelope: envelope) else {
                throw SecurePersistenceError.invalidEncryptedPayload
            }
            return decrypted
        }
        guard canReadLegacyPlaintext(at: url) else {
            throw SecurePersistenceError.invalidEncryptedPayload
        }
        return data
    }

    private static func migrationState(for url: URL) throws -> MigrationState {
        let stateURL = migrationStateURL(for: url)
        guard FileManager.default.fileExists(atPath: stateURL.path) else {
            return MigrationState()
        }
        let data = try Data(contentsOf: stateURL)
        return try JSONDecoder().decode(MigrationState.self, from: data)
    }

    private static func saveMigrationState(_ state: MigrationState, for url: URL) throws {
        let stateURL = migrationStateURL(for: url)
        try ensureStorageDirectory(at: stateURL.deletingLastPathComponent())

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state)
        try data.write(to: stateURL, options: .atomic)
        try hardenFile(at: stateURL)
    }

    private static func migrationStateURL(for url: URL) -> URL {
        url.deletingLastPathComponent().appendingPathComponent(Constants.migrationStateFileName)
    }

    private static func migrationFileIdentifier(for url: URL) -> String {
        url.lastPathComponent
    }

    private static func encrypt(_ plaintext: Data) throws -> Envelope {
        let sealedBox = try AES.GCM.seal(plaintext, using: localKey())
        guard let combined = sealedBox.combined else {
            throw SecurePersistenceError.invalidEncryptedPayload
        }
        return Envelope(
            format: Constants.format,
            algorithm: Constants.algorithm,
            combinedSealedBox: combined.base64EncodedString()
        )
    }

    private static func decrypt(envelope: Envelope) throws -> Data? {
        guard let combined = Data(base64Encoded: envelope.combinedSealedBox) else { return nil }
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        return try AES.GCM.open(sealedBox, using: localKey())
    }

    private static func localKey() throws -> SymmetricKey {
        if let data = try keychainData() {
            guard data.count == Constants.keyByteCount else {
                throw SecurePersistenceError.invalidKeychainData
            }
            return SymmetricKey(data: data)
        }

        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        try setKeychainData(data)
        return key
    }

    private static func keychainData() throws -> Data? {
        var query = keychainBaseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw SecurePersistenceError.keychainStatus(status) }
        guard let data = item as? Data else { throw SecurePersistenceError.invalidKeychainData }
        return data
    }

    private static func setKeychainData(_ data: Data) throws {
        var query = keychainBaseQuery()
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw SecurePersistenceError.keychainStatus(updateStatus)
        }

        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw SecurePersistenceError.keychainStatus(addStatus)
        }
    }

    private static func keychainBaseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: Constants.keychainAccount,
        ]
    }
}
