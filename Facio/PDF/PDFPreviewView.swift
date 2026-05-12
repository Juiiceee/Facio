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
    @Environment(DataStore.self) private var dataStore
    @State private var showPDFGenerationAlert = false
    @State private var showPDFExportAlert = false

    private var lang: AppLanguage { dataStore.companyInfo.langueParDefaut }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(L10n.previewTitle(lang, number: document.number))
                    .font(.headline)
                Spacer()
                Button(L10n.exportPDF(lang)) {
                    exportPDF()
                }
                .keyboardShortcut("e", modifiers: .command)

                Button(L10n.close(lang)) {
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
                    L10n.pdfGenerationError(lang),
                    systemImage: "exclamationmark.triangle",
                    description: Text(L10n.cannotGeneratePDF(lang))
                )
            } else {
                PDFPreviewView(data: pdfData)
            }
        }
        .frame(minWidth: 650, minHeight: 850)
        .alert(L10n.pdfGenerationError(lang), isPresented: $showPDFGenerationAlert) {
            Button(L10n.understood(lang), role: .cancel) {}
        } message: {
            Text(L10n.cannotGeneratePDF(lang))
        }
        .alert(L10n.pdfExportError(lang), isPresented: $showPDFExportAlert) {
            Button(L10n.understood(lang), role: .cancel) {}
        } message: {
            Text(L10n.cannotExportPDF(lang))
        }
    }

    private func exportPDF() {
        let pdfData = PDFGenerator(document: document, company: company).generate()
        guard !pdfData.isEmpty else {
            showPDFGenerationAlert = true
            return
        }

        Task {
            let result = await ExportService.exportPDF(data: pdfData, defaultFilename: document.number, language: lang)
            if result == .failed {
                showPDFExportAlert = true
            }
        }
    }
}
