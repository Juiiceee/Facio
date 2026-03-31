import Foundation
import Observation

// MARK: - Sync State

struct SyncState: Codable {
    var documentsDirty: Bool = false
    var clientsDirty: Bool = false
    var companyDirty: Bool = false
    var timesheetsDirty: Bool = false
    var documentsUpdatedAt: Date?
    var clientsUpdatedAt: Date?
    var companyUpdatedAt: Date?
    var timesheetsUpdatedAt: Date?
}

// MARK: - Sync Config

struct SyncConfig {
    // DB partagee par defaut — lue depuis ~/.facio_config
    static var defaultURL: String { Secrets.supabaseURL }
    static var defaultAPIKey: String { Secrets.supabaseAnonKey }

    // Cles UserDefaults
    private static let customURLKey = "supabase_custom_url"
    private static let customAPIKeyKey = "supabase_custom_api_key"
    private static let useCustomKey = "supabase_use_custom"
    private static let enabledKey = "sync_enabled"

    /// Sync activee
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// Utiliser une DB custom au lieu de la DB partagee
    static var useCustomDB: Bool {
        get { UserDefaults.standard.bool(forKey: useCustomKey) }
        set { UserDefaults.standard.set(newValue, forKey: useCustomKey) }
    }

    /// URL custom
    static var customURL: String {
        get { UserDefaults.standard.string(forKey: customURLKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: customURLKey) }
    }

    /// API key custom
    static var customAPIKey: String {
        get { UserDefaults.standard.string(forKey: customAPIKeyKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: customAPIKeyKey) }
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
}

// MARK: - Sync Service

@Observable
@MainActor
final class SyncService: Sendable {
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var lastError: String?
    var syncState: SyncState = SyncState()
    var authService: AuthService?

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var debounceTask: Task<Void, Never>?
    private let syncStateURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Facio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        syncStateURL = dir.appendingPathComponent("sync_state.json")
        loadSyncState()
    }

    // MARK: - Sync State Persistence

    private func loadSyncState() {
        guard let data = try? Data(contentsOf: syncStateURL),
              let state = try? decoder.decode(SyncState.self, from: data)
        else { return }
        syncState = state
    }

    private func saveSyncState() {
        guard let data = try? encoder.encode(syncState) else { return }
        try? data.write(to: syncStateURL, options: .atomic)
    }

    // MARK: - Mark Dirty

    func markDirty(_ key: String) {
        switch key {
        case "documents": syncState.documentsDirty = true
        case "clients": syncState.clientsDirty = true
        case "company": syncState.companyDirty = true
        case "timesheets": syncState.timesheetsDirty = true
        default: break
        }
        saveSyncState()

        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                await pushAllDirty()
            }
        }
    }

    // MARK: - Push

    func pushAllDirty() async {
        guard SyncConfig.isEnabled, SyncConfig.isConfigured,
              authService?.isAuthenticated == true else { return }

        let storageDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Facio", isDirectory: true)

        let keysToSync: [(key: String, isDirty: Bool, file: String)] = [
            ("documents", syncState.documentsDirty, "documents.json"),
            ("clients", syncState.clientsDirty, "clients.json"),
            ("company", syncState.companyDirty, "company.json"),
            ("timesheets", syncState.timesheetsDirty, "timesheets.json"),
        ]

        for entry in keysToSync where entry.isDirty {
            let fileURL = storageDir.appendingPathComponent(entry.file)
            guard let fileData = try? Data(contentsOf: fileURL) else { continue }

            let success = await pushToSupabase(key: entry.key, jsonData: fileData)
            if success {
                switch entry.key {
                case "documents": syncState.documentsDirty = false; syncState.documentsUpdatedAt = Date()
                case "clients": syncState.clientsDirty = false; syncState.clientsUpdatedAt = Date()
                case "company": syncState.companyDirty = false; syncState.companyUpdatedAt = Date()
                case "timesheets": syncState.timesheetsDirty = false; syncState.timesheetsUpdatedAt = Date()
                default: break
                }
            }
        }
        saveSyncState()
    }

    /// UPSERT : INSERT avec ON CONFLICT → UPDATE
    /// Utilise POST + Prefer: resolution=merge-duplicates
    /// La contrainte UNIQUE(user_id, key) gere le merge
    private func pushToSupabase(key: String, jsonData: Data) async -> Bool {
        guard let auth = authService, auth.isAuthenticated else { return false }
        // on-conflict sur la contrainte unique (user_id, key)
        guard let url = buildURL(path: "/rest/v1/sync_data?on_conflict=user_id,key") else { return false }

        let now = ISO8601DateFormatter().string(from: Date())
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "[]"
        let bodyString = """
        {"user_id":"\(auth.userId)","key":"\(key)","data":\(jsonString),"updated_at":"\(now)"}
        """
        guard let bodyData = bodyString.data(using: .utf8) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        addHeaders(&request, token: auth.accessToken)
        // resolution=merge-duplicates fait l'UPSERT
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")

        do {
            isSyncing = true
            let (responseData, response) = try await URLSession.shared.data(for: request)
            isSyncing = false

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    lastSyncDate = Date()
                    lastError = nil
                    return true
                }
                // Lire l'erreur Supabase
                if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                   let msg = json["message"] as? String ?? json["msg"] as? String {
                    lastError = msg
                } else {
                    lastError = "Erreur HTTP \(httpResponse.statusCode)"
                }
            }
            return false
        } catch {
            isSyncing = false
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Pull

    func pullFromSupabase(key: String) async -> (data: Data, updatedAt: Date)? {
        guard let auth = authService, auth.isAuthenticated else { return nil }
        guard let url = buildURL(path: "/rest/v1/sync_data?user_id=eq.\(auth.userId)&key=eq.\(key)&select=data,updated_at") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(&request, token: auth.accessToken)

        do {
            isSyncing = true
            let (data, response) = try await URLSession.shared.data(for: request)
            isSyncing = false

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let first = jsonArray.first,
                  let remoteData = first["data"],
                  let updatedAtStr = first["updated_at"] as? String,
                  let updatedAt = ISO8601DateFormatter().date(from: updatedAtStr)
            else { return nil }

            let remoteJsonData = try JSONSerialization.data(withJSONObject: remoteData)
            return (remoteJsonData, updatedAt)
        } catch {
            isSyncing = false
            lastError = error.localizedDescription
            return nil
        }
    }

    // MARK: - Full Sync

    func fullSync(dataStore: DataStore) async {
        guard SyncConfig.isEnabled, SyncConfig.isConfigured,
              authService?.isAuthenticated == true else { return }

        await pushAllDirty()

        await pullIfNewer(key: "documents", localDate: syncState.documentsUpdatedAt) { data in
            if let docs = try? self.decoder.decode([Document].self, from: data) {
                dataStore.documents = docs
                dataStore.saveLocal(key: "documents")
            }
        }
        await pullIfNewer(key: "clients", localDate: syncState.clientsUpdatedAt) { data in
            if let clients = try? self.decoder.decode([ClientInfo].self, from: data) {
                dataStore.clients = clients
                dataStore.saveLocal(key: "clients")
            }
        }
        await pullIfNewer(key: "company", localDate: syncState.companyUpdatedAt) { data in
            if let company = try? self.decoder.decode(CompanyInfo.self, from: data) {
                dataStore.companyInfo = company
                dataStore.saveLocal(key: "company")
            }
        }
        await pullIfNewer(key: "timesheets", localDate: syncState.timesheetsUpdatedAt) { data in
            if let ts = try? self.decoder.decode([TimesheetPeriod].self, from: data) {
                dataStore.timesheets = ts
                dataStore.saveLocal(key: "timesheets")
            }
        }

        lastSyncDate = Date()
    }

    private func pullIfNewer(key: String, localDate: Date?, apply: (Data) -> Void) async {
        guard let remote = await pullFromSupabase(key: key) else { return }
        if let localDate = localDate, localDate >= remote.updatedAt { return }
        apply(remote.data)
        switch key {
        case "documents": syncState.documentsUpdatedAt = remote.updatedAt
        case "clients": syncState.clientsUpdatedAt = remote.updatedAt
        case "company": syncState.companyUpdatedAt = remote.updatedAt
        case "timesheets": syncState.timesheetsUpdatedAt = remote.updatedAt
        default: break
        }
        saveSyncState()
    }

    // MARK: - Helpers

    private func buildURL(path: String) -> URL? {
        let base = SyncConfig.url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(base)\(path)")
    }

    private func addHeaders(_ request: inout URLRequest, token: String? = nil) {
        request.addValue(SyncConfig.apiKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(token ?? SyncConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}
