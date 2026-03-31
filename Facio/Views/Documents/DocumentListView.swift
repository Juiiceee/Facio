import SwiftUI

struct DocumentListView: View {
    let documentType: DocumentType
    @Binding var selectedDocumentId: UUID?

    @Environment(DataStore.self) private var dataStore
    @State private var searchText = ""

    private var allDocuments: [Document] {
        dataStore.documents.sorted { $0.dateCreation > $1.dateCreation }
    }

    private var documents: [Document] {
        let filtered = allDocuments.filter { $0.type == documentType }
        guard !searchText.isEmpty else { return filtered }
        let query = searchText.lowercased()
        return filtered.filter { doc in
            doc.number.lowercased().contains(query) ||
            doc.clientNom.lowercased().contains(query)
        }
    }

    var body: some View {
        List(documents, selection: $selectedDocumentId) { document in
            DocumentRowView(document: document)
                .tag(document.id)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        supprimerDocument(document)
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button {
                        dupliquerDocument(document)
                    } label: {
                        Label("Dupliquer", systemImage: "doc.on.doc")
                    }

                    if document.type == .devis {
                        Button {
                            convertirEnFacture(document)
                        } label: {
                            Label("Convertir en Facture", systemImage: "arrow.right.doc.on.clipboard")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        supprimerDocument(document)
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                }
        }
        .navigationTitle(documentType == .devis ? "Devis" : "Factures")
        .searchable(text: $searchText, prompt: "Rechercher par numero ou client")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    creerDocument()
                } label: {
                    Label("Nouveau \(documentType.label)", systemImage: "plus")
                }
            }
        }
        .overlay {
            if documents.isEmpty {
                ContentUnavailableView(
                    "Aucun \(documentType.label.lowercased())",
                    systemImage: documentType == .facture ? "doc.text" : "doc.text.magnifyingglass",
                    description: Text("Cliquez sur + pour creer un \(documentType.label.lowercased()).")
                )
            }
        }
    }

    // MARK: - Actions

    private func creerDocument() {
        let number = DocumentNumberService.nextNumber(
            type: documentType,
            existingDocuments: allDocuments
        )
        let document = Document(type: documentType, number: number)
        dataStore.addDocument(document)
        selectedDocumentId = document.id
    }

    private func supprimerDocument(_ document: Document) {
        if selectedDocumentId == document.id {
            selectedDocumentId = nil
        }
        dataStore.deleteDocument(document)
    }

    private func dupliquerDocument(_ document: Document) {
        let copie = document.dupliquer()
        copie.number = DocumentNumberService.nextNumber(
            type: copie.type,
            existingDocuments: allDocuments
        )
        dataStore.addDocument(copie)
        selectedDocumentId = copie.id
    }

    private func convertirEnFacture(_ document: Document) {
        let facture = document.convertirEnFacture()
        facture.number = DocumentNumberService.nextNumber(
            type: .facture,
            existingDocuments: allDocuments
        )
        dataStore.addDocument(facture)
    }
}

// MARK: - Document Row

struct DocumentRowView: View {
    let document: Document

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(document.number)
                        .font(.headline)
                    Spacer()
                    StatusBadge(status: document.status)
                }

                HStack {
                    Text(document.clientNom.isEmpty ? "Sans client" : document.clientNom)
                        .font(.subheadline)
                        .foregroundStyle(document.clientNom.isEmpty ? .tertiary : .secondary)
                    Spacer()
                    Text(document.dateCreation.frenchFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(document.totalFormatted)
                .font(.body.monospacedDigit())
                .fontWeight(.medium)
                .frame(minWidth: 100, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}
