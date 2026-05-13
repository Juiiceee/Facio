import SwiftUI

struct ClientListView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var searchText = ""
    @State private var selectedClient: ClientInfo?
    @State private var showingNewClient = false

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    private var clients: [ClientInfo] {
        dataStore.clients.sorted { $0.nom < $1.nom }
    }

    private var filteredClients: [ClientInfo] {
        if searchText.isEmpty { return clients }
        return clients.filter {
            $0.nom.localizedCaseInsensitiveContains(searchText) ||
            $0.ville.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText) ||
            $0.siret.localizedCaseInsensitiveContains(searchText) ||
            $0.tva.localizedCaseInsensitiveContains(searchText) ||
            $0.ape.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        HSplitView {
            // Liste
            VStack(spacing: 0) {
                List(filteredClients, selection: $selectedClient) { client in
                    ClientRow(client: client)
                        .tag(client)
                        .contextMenu {
                            Button(L10n.delete(lang), role: .destructive) {
                                deleteClient(client)
                            }
                        }
                }
                .searchable(text: $searchText, prompt: L10n.searchClientPrompt(lang))
            }
            .frame(minWidth: 250)

            // Detail / Editeur
            if let client = selectedClient {
                ClientDetailView(client: client)
            } else {
                ContentUnavailableView(
                    L10n.noClientSelected(lang),
                    systemImage: "person.crop.circle",
                    description: Text(L10n.selectOrCreateClient(lang))
                )
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: createClient) {
                    Label(L10n.newClient(lang), systemImage: "plus")
                }
            }
        }
        .navigationTitle(L10n.sidebarClients(lang))
        .onChange(of: dataStore.clients.map(\.id)) { _, ids in
            if let selectedClient, !ids.contains(selectedClient.id) {
                self.selectedClient = nil
            }
        }
    }

    private func createClient() {
        let client = ClientInfo(nom: L10n.newClient(lang))
        dataStore.addClient(client)
        selectedClient = client
    }

    private func deleteClient(_ client: ClientInfo) {
        if selectedClient == client {
            selectedClient = nil
        }
        dataStore.deleteClient(client)
    }
}

// MARK: - Row

struct ClientRow: View {
    let client: ClientInfo
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(client.nom)
                .fontWeight(.medium)
            if !client.ville.isEmpty {
                Text("\(client.ville), \(client.codePostal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            let identifiers = [
                client.siret.isEmpty ? nil : "\(L10n.siret(lang)): \(client.siret)",
                client.tva.isEmpty ? nil : "\(L10n.vatNumber(lang)): \(client.tva)",
                client.ape.isEmpty ? nil : "\(L10n.apeCode(lang)): \(client.ape)"
            ].compactMap { $0 }
            if !identifiers.isEmpty {
                Text(identifiers.joined(separator: " - "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - Detail

struct ClientDetailView: View {
    var client: ClientInfo
    @Environment(DataStore.self) private var dataStore

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        Form {
            Section(L10n.information(lang)) {
                TextField(L10n.name(lang), text: Bindable(client).nom)
                TextField(L10n.address(lang), text: Bindable(client).adresse)
                TextField(L10n.postalCode(lang), text: Bindable(client).codePostal)
                TextField(L10n.city(lang), text: Bindable(client).ville)
                TextField(L10n.email(lang), text: Bindable(client).email)
                TextField(L10n.siret(lang), text: Bindable(client).siret)
                TextField(L10n.vatNumber(lang), text: Bindable(client).tva)
                TextField(L10n.apeCode(lang), text: Bindable(client).ape)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: client.nom) { dataStore.clientUpdated(client) }
        .onChange(of: client.adresse) { dataStore.clientUpdated(client) }
        .onChange(of: client.codePostal) { dataStore.clientUpdated(client) }
        .onChange(of: client.ville) { dataStore.clientUpdated(client) }
        .onChange(of: client.email) { dataStore.clientUpdated(client) }
        .onChange(of: client.siret) { dataStore.clientUpdated(client) }
        .onChange(of: client.tva) { dataStore.clientUpdated(client) }
        .onChange(of: client.ape) { dataStore.clientUpdated(client) }
    }
}
