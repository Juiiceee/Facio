import SwiftUI
import PDFKit

/// Vue de prévisualisation PDF intégrée (NSViewRepresentable)
struct PDFPreviewView: NSViewRepresentable {
    let data: Data

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.backgroundColor = .windowBackgroundColor
        updateDocument(pdfView)
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        updateDocument(pdfView)
    }

    private func updateDocument(_ pdfView: PDFView) {
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
    }
}

/// Sheet de prévisualisation PDF
struct PDFPreviewSheet: View {
    let document: Document
    let company: CompanyInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Aperçu — \(document.number)")
                    .font(.headline)
                Spacer()
                Button("Exporter PDF") {
                    exportPDF()
                }
                .keyboardShortcut("e", modifiers: .command)

                Button("Fermer") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            // Preview
            let pdfData = PDFGenerator(document: document, company: company).generate()
            if pdfData.isEmpty {
                ContentUnavailableView(
                    "Erreur de génération",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Impossible de générer le PDF.")
                )
            } else {
                PDFPreviewView(data: pdfData)
            }
        }
        .frame(minWidth: 650, minHeight: 850)
    }

    private func exportPDF() {
        let pdfData = PDFGenerator(document: document, company: company).generate()
        guard !pdfData.isEmpty else { return }
        Task {
            await ExportService.exportPDF(data: pdfData, defaultFilename: document.number)
        }
    }
}
