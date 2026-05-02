import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query(filter: #Predicate<RecurringTransaction> { !$0.isSoftDeleted }) private var recurringTransactions: [RecurringTransaction]
    @Query private var budgets: [MonthlyBudget]
    @Query private var categories: [CustomCategory]
    @Query private var groups: [SplitGroupModel]
    
    @State private var viewModel = BackupViewModel()
    
    @State private var showImportPicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.UI.spacing20) {
                exportSection
                importSection
                dataSummarySection
            }
            .padding(.horizontal, AppConstants.UI.padding)
            .padding(.vertical, AppConstants.UI.spacing20)
        }
        .background(AppColors.background)
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
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
        VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
            Text("EXPORT")
                .font(AppTypography.sectionHeader)
                .foregroundStyle(AppColors.label2)

            VStack(spacing: 0) {
                BackupPickerRow(label: "Format", value: viewModel.selectedExportFormat.rawValue) {
                    Picker("", selection: $viewModel.selectedExportFormat) {
                        ForEach(ExportFormat.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                }

                Divider().padding(.leading, AppConstants.UI.padding)

                BackupPickerRow(label: "Data Type", value: viewModel.selectedDataType.rawValue) {
                    Picker("", selection: $viewModel.selectedDataType) {
                        ForEach(ExportDataType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                }

                Divider().padding(.leading, AppConstants.UI.padding)

                Button {
                    Task {
                        await viewModel.exportData(
                            transactions: transactions,
                            recurringTransactions: recurringTransactions,
                            budgets: budgets,
                            categories: categories,
                            groups: groups
                        )
                    }
                } label: {
                    HStack(spacing: AppConstants.UI.spacingSM) {
                        if viewModel.isExporting {
                            ProgressView().tint(AppColors.accent)
                        } else {
                            AppIcon(name: AppIcons.UI.export, size: 18, color: AppColors.accent)
                        }
                        Text("Export \(viewModel.selectedDataType.rawValue)")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.accent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppConstants.UI.padding)
                }
                .buttonStyle(.plain)
                .disabled(transactions.isEmpty && recurringTransactions.isEmpty && budgets.isEmpty && categories.isEmpty)
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))

            Text(viewModel.exportDescription)
                .font(AppTypography.caption1)
                .foregroundStyle(AppColors.label2)
                .padding(.horizontal, AppConstants.UI.spacingSM)
        }
    }

    private var importSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
            Text("IMPORT")
                .font(AppTypography.sectionHeader)
                .foregroundStyle(AppColors.label2)

            VStack(spacing: 0) {
                BackupPickerRow(label: "Format", value: viewModel.selectedImportFormat.rawValue) {
                    Picker("", selection: $viewModel.selectedImportFormat) {
                        ForEach(ExportFormat.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                }

                Divider().padding(.leading, AppConstants.UI.padding)

                Button {
                    showImportPicker = true
                } label: {
                    HStack(spacing: AppConstants.UI.spacingSM) {
                        if viewModel.isImporting {
                            ProgressView().tint(AppColors.accent)
                        } else {
                            AppIcon(name: AppIcons.UI.sync, size: 18, color: AppColors.accent)
                        }
                        Text("Import from \(viewModel.selectedImportFormat.rawValue)")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.accent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppConstants.UI.padding)
                }
                .buttonStyle(.plain)
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        }
    }

    private var dataSummarySection: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
            Text("DATA SUMMARY")
                .font(AppTypography.sectionHeader)
                .foregroundStyle(AppColors.label2)

            VStack(spacing: 0) {
                SummaryRow(icon: AppIcons.UI.transactions, label: "Transactions", count: transactions.count)
                Divider().padding(.leading, AppConstants.UI.iconBadgeSize + AppConstants.UI.padding + AppConstants.UI.spacing12)
                SummaryRow(icon: AppIcons.UI.budget, label: "Budgets", count: budgets.count)
                Divider().padding(.leading, AppConstants.UI.iconBadgeSize + AppConstants.UI.padding + AppConstants.UI.spacing12)
                SummaryRow(icon: AppIcons.UI.categories, label: "Categories", count: categories.count)
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        }
    }
}

private struct BackupPickerRow<Content: View>: View {
    let label: String
    let value: String
    @ViewBuilder let picker: () -> Content

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.label)
            Spacer()
            picker()
                .tint(AppColors.accent)
                .font(AppTypography.body)
        }
        .padding(.horizontal, AppConstants.UI.padding)
        .padding(.vertical, 14)
    }
}

private struct SummaryRow: View {
    let icon: String
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: AppConstants.UI.spacing12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.accent)
                    .frame(width: AppConstants.UI.iconBadgeSize, height: AppConstants.UI.iconBadgeSize)
                AppIcon(name: icon, size: AppConstants.UI.iconBadgeSize * 0.52, color: .white)
            }
            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.label)
            Spacer()
            Text("\(count)")
                .font(AppTypography.body)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.label)
        }
        .padding(.horizontal, AppConstants.UI.padding)
        .padding(.vertical, AppConstants.UI.spacing12)
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
                AppLogger.export.error("Error copying file for import: \(error)")
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
    .modelContainer(for: [Transaction.self, MonthlyBudget.self, CustomCategory.self], inMemory: true)
}
