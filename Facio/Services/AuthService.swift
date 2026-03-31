import Foundation
import Observation

/// Tokens de session persistes dans un fichier JSON local
private struct SessionData: Codable {
    var accessToken: String = ""
    var refreshToken: String = ""
    var userId: String = ""
    var userEmail: String = ""
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

    private let sessionURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Facio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        sessionURL = dir.appendingPathComponent("auth_session.json")

        // Restaurer la session depuis le fichier
        if let data = try? Data(contentsOf: sessionURL),
           let session = try? JSONDecoder().decode(SessionData.self, from: data) {
            accessToken = session.accessToken
            refreshToken = session.refreshToken
            userId = session.userId
            userEmail = session.userEmail
            isAuthenticated = !accessToken.isEmpty && !userId.isEmpty
        }
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
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode >= 200 && httpResponse.statusCode < 300,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                signOut()
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
        awaitingOTP = false
        pendingEmail = ""
        try? FileManager.default.removeItem(at: sessionURL)
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
        let session = SessionData(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: userId,
            userEmail: userEmail
        )
        if let data = try? JSONEncoder().encode(session) {
            try? data.write(to: sessionURL, options: .atomic)
        }
    }

    private func buildURL(path: String) -> URL? {
        let base = SyncConfig.url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(base)\(path)")
    }
}
