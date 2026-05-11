import Foundation
import Observation

/// Etat de session non sensible persiste dans un fichier JSON local.
/// Les champs token restent decodables pour migrer les anciennes sessions.
private struct SessionData: Codable {
    var accessToken: String = ""
    var refreshToken: String = ""
    var userId: String = ""
    var userEmail: String = ""

    enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken, userId, userEmail
    }

    init(
        accessToken: String = "",
        refreshToken: String = "",
        userId: String = "",
        userEmail: String = ""
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userId = userId
        self.userEmail = userEmail
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = container.decodeOrDefault(String.self, forKey: .accessToken, default: "")
        refreshToken = container.decodeOrDefault(String.self, forKey: .refreshToken, default: "")
        userId = container.decodeOrDefault(String.self, forKey: .userId, default: "")
        userEmail = container.decodeOrDefault(String.self, forKey: .userEmail, default: "")
    }
}

/// Gere l'authentification Supabase via OTP (code par email).
/// Sync opt-in, local par defaut.
@Observable
@MainActor
final class AuthService: Sendable {
    var isAuthenticated: Bool = false
    var userEmail: String = ""
    var userId: String = ""
    var accessToken: String = ""
    var refreshToken: String = ""
    var error: String?
    var isLoading: Bool = false

    /// true apres envoi du code OTP, en attente de verification
    var awaitingOTP: Bool = false
    /// Email pour lequel on attend le code
    var pendingEmail: String = ""

    private enum KeychainAccount {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    private let sessionURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Facio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        sessionURL = dir.appendingPathComponent("auth_session.json")

        // Restaurer l'etat non sensible depuis le fichier, puis les tokens depuis Keychain.
        if let data = try? Data(contentsOf: sessionURL),
           let session = try? JSONDecoder().decode(SessionData.self, from: data) {
            userId = session.userId
            userEmail = session.userEmail

            if !session.accessToken.isEmpty || !session.refreshToken.isEmpty {
                migrateLegacyTokens(accessToken: session.accessToken, refreshToken: session.refreshToken)
            }
        }

        accessToken = (try? KeychainService.string(for: KeychainAccount.accessToken)) ?? ""
        refreshToken = (try? KeychainService.string(for: KeychainAccount.refreshToken)) ?? ""
        isAuthenticated = !accessToken.isEmpty && !userId.isEmpty
    }

    // MARK: - OTP : Envoyer le code

    /// Envoie un code OTP a 6 chiffres par email via Supabase
    func sendOTP(email: String) async {
        guard SyncConfig.isConfigured else {
            error = "Configuration Supabase manquante"
            return
        }
        guard let url = buildURL(path: "/auth/v1/otp") else { return }

        isLoading = true
        error = nil

        let body: [String: Any] = [
            "email": email,
            "create_user": true,
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            isLoading = false
            return
        }

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
                pendingEmail = email
                awaitingOTP = true
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["msg"] as? String ?? json["error_description"] as? String ?? json["message"] as? String {
                    error = msg
                } else {
                    error = "Erreur d'envoi du code (HTTP \(httpResponse.statusCode))"
                }
            }
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    // MARK: - OTP : Verifier le code

    /// Verifie le code OTP saisi par l'utilisateur
    func verifyOTP(code: String) async {
        guard SyncConfig.isConfigured else {
            error = "Configuration Supabase manquante"
            return
        }
        guard let url = buildURL(path: "/auth/v1/verify") else { return }

        isLoading = true
        error = nil

        let body: [String: Any] = [
            "email": pendingEmail,
            "token": code,
            "type": "email",
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            isLoading = false
            return
        }

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
                    awaitingOTP = false
                    pendingEmail = ""
                }
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json["msg"] as? String ?? json["error_description"] as? String ?? json["message"] as? String {
                    error = msg
                } else {
                    error = "Code invalide ou expire"
                }
            }
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    // MARK: - Annuler OTP

    func cancelOTP() {
        awaitingOTP = false
        pendingEmail = ""
        error = nil
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
            guard let httpResponse = response as? HTTPURLResponse else {
                error = "Reponse Supabase invalide"
                return
            }

            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    error = "Reponse Supabase invalide"
                    return
                }
                handleAuthResponse(json)
                return
            }

            if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 {
                signOut()
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["msg"] as? String ?? json["error_description"] as? String ?? json["message"] as? String {
                error = msg
            } else {
                error = "Erreur de rafraichissement de session (HTTP \(httpResponse.statusCode))"
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Deconnexion

    func signOut() {
        accessToken = ""
        refreshToken = ""
        userId = ""
        userEmail = ""
        isAuthenticated = false
        awaitingOTP = false
        pendingEmail = ""
        try? FileManager.default.removeItem(at: sessionURL)
        try? KeychainService.delete(account: KeychainAccount.accessToken)
        try? KeychainService.delete(account: KeychainAccount.refreshToken)
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
        persistTokens()
        persistSessionState()
    }

    private func migrateLegacyTokens(accessToken legacyAccessToken: String, refreshToken legacyRefreshToken: String) {
        do {
            if !legacyAccessToken.isEmpty {
                try KeychainService.set(legacyAccessToken, for: KeychainAccount.accessToken)
            }
            if !legacyRefreshToken.isEmpty {
                try KeychainService.set(legacyRefreshToken, for: KeychainAccount.refreshToken)
            }
            persistSessionState()
        } catch {
            self.error = "Erreur de migration de la session"
        }
    }

    private func persistTokens() {
        do {
            try KeychainService.set(accessToken, for: KeychainAccount.accessToken)
            try KeychainService.set(refreshToken, for: KeychainAccount.refreshToken)
        } catch {
            self.error = "Erreur d'enregistrement de la session"
        }
    }

    private func persistSessionState() {
        let session = SessionData(
            accessToken: "",
            refreshToken: "",
            userId: userId,
            userEmail: userEmail
        )
        if let data = try? JSONEncoder().encode(session) {
            try? data.write(to: sessionURL, options: .atomic)
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: sessionURL.path)
        }
    }

    private func buildURL(path: String) -> URL? {
        guard var components = URLComponents(string: SyncConfig.url.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = components.scheme?.lowercased(),
              let host = components.host,
              !host.isEmpty else {
            error = "URL Supabase invalide"
            return nil
        }

        guard components.user == nil,
              components.password == nil,
              components.fragment == nil else {
            error = "URL Supabase invalide"
            return nil
        }

        if scheme == "http" {
            #if DEBUG
            guard isLocalhost(host) else {
                error = "URL Supabase non securisee"
                return nil
            }
            #else
            error = "URL Supabase non securisee"
            return nil
            #endif
        } else if scheme != "https" {
            error = "URL Supabase invalide"
            return nil
        }

        guard let pathComponents = URLComponents(string: path) else {
            error = "URL Supabase invalide"
            return nil
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let requestPath = pathComponents.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + [basePath, requestPath]
            .filter { !$0.isEmpty }
            .joined(separator: "/")
        components.query = pathComponents.query
        components.fragment = nil

        return components.url
    }

    private func isLocalhost(_ host: String) -> Bool {
        let normalizedHost = host.lowercased()
        return normalizedHost == "localhost"
            || normalizedHost == "127.0.0.1"
            || normalizedHost == "::1"
    }
}
