import Foundation
import Security

enum KeychainService {
    enum KeychainError: Error {
        case unexpectedData
        case unhandledStatus(OSStatus)
    }

    private static let service = "com.facio.auth"

    #if DEBUG
    // En dev, on évite le trousseau (pop-ups répétées en build non signé).
    private static func devKey(_ account: String) -> String { "auth.\(account)" }
    #endif

    static func string(for account: String) throws -> String? {
        #if DEBUG
        return DevSecretStore.data(for: devKey(account)).flatMap { String(data: $0, encoding: .utf8) }
        #else
        var query = baseQuery(account: account)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }
        guard let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return value
        #endif
    }

    static func set(_ value: String, for account: String) throws {
        #if DEBUG
        DevSecretStore.set(Data(value.utf8), for: devKey(account))
        return
        #else
        let data = Data(value.utf8)
        var query = baseQuery(account: account)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess {
            return
        }
        guard status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }

        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.unhandledStatus(addStatus)
        }
        #endif
    }

    static func delete(account: String) throws {
        #if DEBUG
        DevSecretStore.delete(devKey(account))
        #else
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
        #endif
    }

    static func deleteAll() throws {
        #if DEBUG
        DevSecretStore.deleteAll(withPrefix: "auth.")
        #else
        let status = SecItemDelete(serviceQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledStatus(status)
        }
        #endif
    }

    private static func baseQuery(account: String) -> [String: Any] {
        var query = serviceQuery()
        query[kSecAttrAccount as String] = account
        return query
    }

    private static func serviceQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
    }
}
