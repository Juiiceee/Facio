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
            $0.email.localizedCaseInsensitiveContains(searchText)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(client.nom)
                .fontWeight(.medium)
            if !client.ville.isEmpty {
                Text("\(client.ville), \(client.codePostal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: client.nom) { dataStore.save() }
        .onChange(of: client.adresse) { dataStore.save() }
        .onChange(of: client.codePostal) { dataStore.save() }
        .onChange(of: client.ville) { dataStore.save() }
        .onChange(of: client.email) { dataStore.save() }
    }
}
