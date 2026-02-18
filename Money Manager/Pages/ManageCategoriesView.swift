import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    @StateObject private var viewModel = ManageCategoriesViewModel()
    
    var body: some View {
        List {
            Section {
                ForEach(PredefinedCategory.allCases) { category in
                    HStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .frame(width: 28)
                        
                        Text(category.rawValue)
                            .font(.body)
                        
                        Spacer()
                        
                        Text("Default")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                    }
                }
            } header: {
                Text("Default Categories")
            } footer: {
                Text("Default categories cannot be edited or removed.")
            }
            
            if !viewModel.visibleCategories.isEmpty {
                Section("Your Categories") {
                    ForEach(viewModel.visibleCategories) { category in
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .foregroundColor(Color(hex: category.color))
                                .frame(width: 28)
                            
                            Text(category.name)
                                .font(.body)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.hideCategory(at: index)
                        }
                    }
                }
            }
            
            if !viewModel.hiddenCategories.isEmpty {
                Section("Hidden Categories") {
                    ForEach(viewModel.hiddenCategories) { category in
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .foregroundColor(Color(hex: category.color).opacity(0.5))
                                .frame(width: 28)
                            
                            Text(category.name)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Restore") {
                                viewModel.restoreCategory(category)
                            }
                            .font(.caption)
                            .foregroundColor(.teal)
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.teal)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddCategory) {
            AddCategorySheet()
        }
        .onAppear {
            viewModel.configure(customCategories: customCategories, modelContext: modelContext)
        }
    }
}

struct AddCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel = AddCategoryViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g., Subscriptions, Pets", text: $viewModel.name)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(viewModel.iconOptions, id: \.self) { icon in
                            Button {
                                viewModel.selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(viewModel.selectedIcon == icon ? Color(hex: viewModel.selectedColor) : .secondary)
                                    .frame(width: 44, height: 44)
                                    .background(viewModel.selectedIcon == icon ? Color(hex: viewModel.selectedColor).opacity(0.12) : Color.clear)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(viewModel.colorOptions, id: \.self) { color in
                            Button {
                                viewModel.selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: viewModel.selectedColor == color ? 2.5 : 0)
                                            .padding(-3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Preview") {
                    HStack(spacing: 12) {
                        Image(systemName: viewModel.selectedIcon)
                            .font(.title2)
                            .foregroundColor(Color(hex: viewModel.selectedColor))
                            .frame(width: 36)
                        
                        Text(viewModel.name.isEmpty ? "Category Name" : viewModel.name)
                            .font(.body)
                            .foregroundColor(viewModel.name.isEmpty ? .secondary : .primary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Add") {
                            Task {
                                if await viewModel.save() {
                                    dismiss()
                                }
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ManageCategoriesView()
    }
    .modelContainer(for: [CustomCategory.self])
}
