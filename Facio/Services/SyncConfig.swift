import Foundation
import Security

struct SyncConfig {
    struct SupabaseConfiguration: Equatable {
        let url: String
        let apiKey: String
    }

    // Configuration publique Supabase. La securite repose sur auth + RLS.
    static var defaultURL: String { Secrets.supabaseURL }
    static var defaultAPIKey: String { Secrets.supabaseAnonKey }

    private static let customURLKey = "supabase_custom_url"
    private static let customAPIKeyKey = "supabase_custom_api_key"
    private static let useCustomKey = "supabase_use_custom"
    private static let enabledKey = "sync_enabled"
    private static let legacyEnabledKey = "facio_sync_enabled"
    private static let configurationURLNotificationKey = "url"
    private static let configurationAPIKeyNotificationKey = "apiKey"

    static let supabaseConfigurationDidChangeNotification = Notification.Name(
        "app.facio.supabaseConfigurationDidChange"
    )

    /// Sync activee
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// Utiliser une DB custom au lieu de la DB partagee
    static var useCustomDB: Bool {
        get { UserDefaults.standard.bool(forKey: useCustomKey) }
        set {
            updateSupabaseConfigurationIfNeeded {
                UserDefaults.standard.set(newValue, forKey: useCustomKey)
            }
        }
    }

    /// URL custom
    static var customURL: String {
        get { UserDefaults.standard.string(forKey: customURLKey) ?? "" }
        set {
            updateSupabaseConfigurationIfNeeded {
                UserDefaults.standard.set(newValue, forKey: customURLKey)
            }
        }
    }

    /// API key custom
    static var customAPIKey: String {
        get {
            if let keychainValue = SyncKeychain.string(for: customAPIKeyKey) {
                _ = SyncKeychain.set(keychainValue, for: customAPIKeyKey)
                return keychainValue
            }
            guard let legacyValue = UserDefaults.standard.string(forKey: customAPIKeyKey),
                  !legacyValue.isEmpty
            else { return "" }
            guard SyncKeychain.set(legacyValue, for: customAPIKeyKey) else { return "" }
            UserDefaults.standard.removeObject(forKey: customAPIKeyKey)
            return legacyValue
        }
        set {
            updateSupabaseConfigurationIfNeeded {
                if newValue.isEmpty {
                    SyncKeychain.delete(customAPIKeyKey)
                    UserDefaults.standard.removeObject(forKey: customAPIKeyKey)
                } else if SyncKeychain.set(newValue, for: customAPIKeyKey) {
                    UserDefaults.standard.removeObject(forKey: customAPIKeyKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: customAPIKeyKey)
                }
            }
        }
    }

    /// URL effective (custom ou par defaut)
    static var url: String {
        useCustomDB && !customURL.isEmpty ? customURL : defaultURL
    }

    /// API key effective
    static var apiKey: String {
        useCustomDB && !customAPIKey.isEmpty ? customAPIKey : defaultAPIKey
    }

    static var isConfigured: Bool {
        !url.isEmpty && !apiKey.isEmpty
    }

    static var currentSupabaseConfiguration: SupabaseConfiguration {
        SupabaseConfiguration(url: url, apiKey: apiKey)
    }

    static func supabaseConfiguration(from notification: Notification) -> SupabaseConfiguration? {
        guard let url = notification.userInfo?[configurationURLNotificationKey] as? String,
              let apiKey = notification.userInfo?[configurationAPIKeyNotificationKey] as? String
        else { return nil }
        return SupabaseConfiguration(url: url, apiKey: apiKey)
    }

    static func resetStoredState() {
        let previousConfiguration = currentSupabaseConfiguration

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: enabledKey)
        defaults.removeObject(forKey: legacyEnabledKey)
        defaults.removeObject(forKey: useCustomKey)
        defaults.removeObject(forKey: customURLKey)
        defaults.removeObject(forKey: customAPIKeyKey)
        SyncKeychain.delete(customAPIKeyKey)

        invalidateAuthIfNeeded(previousConfiguration: previousConfiguration)
        AuthService.clearStoredSession()
    }

    private static func updateSupabaseConfigurationIfNeeded(_ update: () -> Void) {
        let previousConfiguration = currentSupabaseConfiguration
        update()
        invalidateAuthIfNeeded(previousConfiguration: previousConfiguration)
    }

    private static func invalidateAuthIfNeeded(previousConfiguration: SupabaseConfiguration) {
        let currentConfiguration = currentSupabaseConfiguration
        guard previousConfiguration != currentConfiguration else { return }

        NotificationCenter.default.post(
            name: supabaseConfigurationDidChangeNotification,
            object: nil,
            userInfo: [
                configurationURLNotificationKey: previousConfiguration.url,
                configurationAPIKeyNotificationKey: previousConfiguration.apiKey,
            ]
        )
        AuthService.clearStoredSession()
    }
}

private enum SyncKeychain {
    private static let service = "app.facio.sync"

    static func string(for account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func set(_ value: String, for account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let query = baseQuery(account: account)
        let update: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return true }
        guard status == errSecItemNotFound else { return false }

        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func delete(_ account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
