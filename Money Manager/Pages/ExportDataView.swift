import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [Expense]
    @Query private var recurringExpenses: [RecurringExpense]
    @Query private var budgets: [MonthlyBudget]
    @Query private var categories: [CustomCategory]
    
    @State private var viewModel = BackupViewModel()
    
    @State private var showImportPicker = false
    
    var body: some View {
        List {
            exportSection
            importSection
            dataSummarySection
        }
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.selectedImportFormat = .json
                        showImportPicker = true
                    } label: {
                        Label("Import JSON", systemImage: "doc.text")
                    }
                    Button {
                        viewModel.selectedImportFormat = .csv
                        showImportPicker = true
                    } label: {
                        Label("Import CSV", systemImage: "tablecells")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showImportPicker) {
            DocumentPicker(
                contentTypes: viewModel.selectedImportFormat == .json ? [.json] : [.commaSeparatedText],
                onPick: { url in
                    Task {
                        await viewModel.importData(from: url, context: modelContext)
                    }
                }
            )
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.successMessage ?? "Operation completed")
        }
    }
    
    private var exportSection: some View {
        Section {
            Picker("Format", selection: $viewModel.selectedExportFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            
            Picker("Data Type", selection: $viewModel.selectedDataType) {
                ForEach(ExportDataType.allCases) { dataType in
                    Label(dataType.rawValue, systemImage: dataType.icon).tag(dataType)
                }
            }
            
            Button {
                Task {
                    await viewModel.exportData(
                        expenses: expenses,
                        recurringExpenses: recurringExpenses,
                        budgets: budgets,
                        categories: categories
                    )
                }
            } label: {
                HStack {
                    if viewModel.isExporting {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text("Export \(viewModel.selectedDataType.rawValue)")
                }
            }
            .disabled(expenses.isEmpty && recurringExpenses.isEmpty && budgets.isEmpty && categories.isEmpty)
        } header: {
            Text("Export")
        } footer: {
            Text(viewModel.exportDescription)
        }
    }
    
    private var importSection: some View {
        Section {
            Picker("Format", selection: $viewModel.selectedImportFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            
            Button {
                showImportPicker = true
            } label: {
                HStack {
                    if viewModel.isImporting {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text("Import from \(viewModel.selectedImportFormat.rawValue)")
                }
            }
        } header: {
            Text("Import")
        } footer: {
            Text(viewModel.importDescription)
        }
    }
    
    private var dataSummarySection: some View {
        Section("Data Summary") {
            HStack {
                Label("Expenses", systemImage: "creditcard.fill")
                Spacer()
                Text("\(expenses.count)")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("Budgets", systemImage: "chart.bar.fill")
                Spacer()
                Text("\(budgets.count)")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("Categories", systemImage: "folder.fill")
                Spacer()
                Text("\(categories.count)")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: tempURL)
            
            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                onPick(tempURL)
            } catch {
                print("Error copying file: \(error)")
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ExportDataView()
    }
    .modelContainer(for: [Expense.self, MonthlyBudget.self, CustomCategory.self], inMemory: true)
}
