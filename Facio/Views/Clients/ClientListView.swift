import SwiftUI

struct ClientListView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var searchText = ""
    @State private var selectedClient: ClientInfo?
    @State private var showingNewClient = false

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
                            Button("Supprimer", role: .destructive) {
                                deleteClient(client)
                            }
                        }
                }
                .searchable(text: $searchText, prompt: "Rechercher un client...")
            }
            .frame(minWidth: 250)

            // Detail / Editeur
            if let client = selectedClient {
                ClientDetailView(client: client)
            } else {
                ContentUnavailableView(
                    "Aucun client selectionne",
                    systemImage: "person.crop.circle",
                    description: Text("Selectionnez un client ou creez-en un nouveau.")
                )
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: createClient) {
                    Label("Nouveau client", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Clients")
    }

    private func createClient() {
        let client = ClientInfo(nom: "Nouveau client")
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

    var body: some View {
        Form {
            Section("Informations") {
                TextField("Nom", text: Bindable(client).nom)
                TextField("Adresse", text: Bindable(client).adresse)
                HStack {
                    TextField("Code postal", text: Bindable(client).codePostal)
                        .frame(width: 100)
                    TextField("Ville", text: Bindable(client).ville)
                }
                TextField("Email", text: Bindable(client).email)
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
