import Foundation
import Observation
import Security

/// Gere l'authentification Supabase
/// Mode par defaut : anonymous auth (zero config, auto au lancement)
/// Mode avance : email + mot de passe
@Observable
@MainActor
final class AuthService: Sendable {
    var isAuthenticated: Bool = false
    var isAnonymous: Bool = false
    var userEmail: String = ""
    var userId: String = ""
    var accessToken: String = ""
    var refreshToken: String = ""
    var error: String?
    var isLoading: Bool = false

    private let tokenKey = "facio_access_token"
    private let refreshKey = "facio_refresh_token"
    private let userIdKey = "facio_user_id"
    private let emailKey = "facio_user_email"
    private let anonKey = "facio_is_anonymous"

    init() {
        // Restaurer la session
        accessToken = keychainRead(key: tokenKey) ?? ""
        refreshToken = keychainRead(key: refreshKey) ?? ""
        userId = UserDefaults.standard.string(forKey: userIdKey) ?? ""
        userEmail = UserDefaults.standard.string(forKey: emailKey) ?? ""
        isAnonymous = UserDefaults.standard.bool(forKey: anonKey)
        isAuthenticated = !accessToken.isEmpty && !userId.isEmpty
    }

    // MARK: - Anonymous Auth (zero config)

    /// Connexion anonyme automatique — cree un user invisible
    func signInAnonymously() async {
        guard SyncConfig.isConfigured else { return }
        guard !isAuthenticated else { return }
        guard let url = buildURL(path: "/auth/v1/signup") else { return }

        isLoading = true
        error = nil

        // Supabase anonymous sign-in : body vide avec header GoTrue
        let bodyString = "{}"
        guard let bodyData = bodyString.data(using: .utf8) else {
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(SyncConfig.apiKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(SyncConfig.apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            isLoading = false

            guard let httpResponse = response as? HTTPURLResponse else { return }

            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    handleAuthResponse(json)
                    isAnonymous = true
                    UserDefaults.standard.set(true, forKey: anonKey)
                }
            } else {
                // Lire l'erreur
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["msg"] as? String ?? json["error_description"] as? String ?? json["message"] as? String {
                    self.error = msg
                } else {
                    self.error = "Erreur anonymous auth (HTTP \(httpResponse.statusCode))"
                }
            }
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    // MARK: - Email Auth

    func signUp(email: String, password: String) async {
        guard SyncConfig.isConfigured else {
            error = "Configuration Supabase manquante"
            return
        }
        guard let url = buildURL(path: "/auth/v1/signup") else { return }

        isLoading = true
        error = nil

        let body: [String: String] = ["email": email, "password": password]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(SyncConfig.apiKey, forHTTPHeaderField: "apikey")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            isLoading = false

            guard let httpResponse = response as? HTTPURLResponse else { return }

            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    handleAuthResponse(json)
                    isAnonymous = false
                    UserDefaults.standard.set(false, forKey: anonKey)
                }
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["msg"] as? String ?? json["error_description"] as? String ?? json["message"] as? String {
                    error = msg
                } else {
                    error = "Erreur d'inscription (HTTP \(httpResponse.statusCode))"
                }
            }
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        guard SyncConfig.isConfigured else {
            error = "Configuration Supabase manquante"
            return
        }
        guard let url = buildURL(path: "/auth/v1/token?grant_type=password") else { return }

        isLoading = true
        error = nil

        let body: [String: String] = ["email": email, "password": password]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(SyncConfig.apiKey, forHTTPHeaderField: "apikey")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            isLoading = false

            guard let httpResponse = response as? HTTPURLResponse else { return }

            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    handleAuthResponse(json)
                    isAnonymous = false
                    UserDefaults.standard.set(false, forKey: anonKey)
                }
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["msg"] as? String ?? json["error_description"] as? String ?? json["message"] as? String {
                    error = msg
                } else {
                    error = "Email ou mot de passe incorrect"
                }
            }
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    // MARK: - Refresh Token

    func refreshSession() async {
        guard !refreshToken.isEmpty,
              let url = buildURL(path: "/auth/v1/token?grant_type=refresh_token") else { return }

        let body: [String: String] = ["refresh_token": refreshToken]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(SyncConfig.apiKey, forHTTPHeaderField: "apikey")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode >= 200 && httpResponse.statusCode < 300,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                // Token expire — re-auth anonyme si besoin
                if isAnonymous {
                    signOut()
                    await signInAnonymously()
                } else {
                    signOut()
                }
                return
            }
            handleAuthResponse(json)
        } catch {
            // Pas de reseau — garder la session
        }
    }

    // MARK: - Deconnexion

    func signOut() {
        accessToken = ""
        refreshToken = ""
        userId = ""
        userEmail = ""
        isAuthenticated = false
        isAnonymous = false
        persistSession()
    }

    // MARK: - Device ID (Keychain — survit aux reinstalls)

    private func getOrCreateDeviceId() -> String {
        if let existing = keychainRead(key: "facio_device_id") {
            return existing
        }
        let newId = UUID().uuidString
        keychainWrite(key: "facio_device_id", value: newId)
        return newId
    }

    // MARK: - Keychain

    func keychainRead(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.juiceeedev.facio",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    func keychainWrite(key: String, value: String) -> Bool {
        let data = value.data(using: .utf8)!
        // Supprimer l'ancien si existant
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.juiceeedev.facio",
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.juiceeedev.facio",
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Helpers

    private func handleAuthResponse(_ json: [String: Any]) {
        if let token = json["access_token"] as? String {
            accessToken = token
        }
        if let refresh = json["refresh_token"] as? String {
            refreshToken = refresh
        }
        if let user = json["user"] as? [String: Any] {
            if let id = user["id"] as? String { userId = id }
            if let email = user["email"] as? String { userEmail = email }
        }
        isAuthenticated = !accessToken.isEmpty && !userId.isEmpty
        persistSession()
    }

    private func persistSession() {
        keychainWrite(key: tokenKey, value: accessToken)
        keychainWrite(key: refreshKey, value: refreshToken)
        UserDefaults.standard.set(userId, forKey: userIdKey)
        UserDefaults.standard.set(userEmail, forKey: emailKey)
        UserDefaults.standard.set(isAnonymous, forKey: anonKey)
    }

    private func buildURL(path: String) -> URL? {
        let base = SyncConfig.url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(base)\(path)")
    }
}
