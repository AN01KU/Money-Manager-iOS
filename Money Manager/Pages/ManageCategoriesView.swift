import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    @State private var viewModel = ManageCategoriesViewModel()
    
    private var predefinedCategories: [CustomCategory] {
        customCategories.filter { $0.isPredefined && !$0.isHidden }
    }
    
    private var userCategories: [CustomCategory] {
        customCategories.filter { !$0.isPredefined && !$0.isHidden }
    }
    
    private var hiddenCategories: [CustomCategory] {
        customCategories.filter { $0.isHidden }
    }
    
    var body: some View {
        List {
            if !predefinedCategories.isEmpty {
                Section {
                    ForEach(predefinedCategories) { category in
                        CategoryRow(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.impact(.light)
                                viewModel.categoryToEdit = category
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if category.isDeletable {
                                    Button(role: .destructive) {
                                        HapticManager.notification(.warning)
                                        viewModel.deleteCategory(category)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    }
                } header: {
                    Text("Default Categories")
                } footer: {
                    Text("Tap to edit icon, color, or name. Swipe to delete (except Other).")
                }
            }
            
            if !userCategories.isEmpty {
                Section("Your Categories") {
                    ForEach(userCategories) { category in
                        CategoryRow(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.impact(.light)
                                viewModel.categoryToEdit = category
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    HapticManager.notification(.warning)
                                    viewModel.deleteCategory(category)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    HapticManager.impact(.light)
                                    viewModel.hideCategory(category)
                                } label: {
                                    Label("Hide", systemImage: "eye.slash")
                                }
                                .tint(.orange)
                            }
                    }
                }
            }
            
            if !hiddenCategories.isEmpty {
                Section("Hidden Categories") {
                    ForEach(hiddenCategories) { category in
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .foregroundStyle(Color(hex: category.color).opacity(0.5))
                                .frame(width: 28)
                            
                            Text(category.name)
                                .font(.body)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button("Restore") {
                                HapticManager.notification(.success)
                                viewModel.restoreCategory(category)
                            }
                            .font(.caption)
                            .foregroundStyle(AppColors.accent)
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.impact(.medium)
                    viewModel.showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddCategory) {
            AddCategorySheet(allCategories: customCategories)
        }
        .sheet(item: $viewModel.categoryToEdit) { category in
            EditCategorySheet(category: category, allCategories: customCategories)
        }
        .alert("Delete Category?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.categoryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            Text("This will permanently remove \"\(viewModel.categoryToDelete?.name ?? "")\". Existing expenses using this category will keep their category name.")
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: CustomCategory
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .foregroundStyle(Color(hex: category.color))
                .frame(width: 28)
            
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            if category.isPredefined {
                Text("Default")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Add Category Sheet

struct AddCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let allCategories: [CustomCategory]
    @State private var viewModel = AddCategoryViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("e.g., Subscriptions, Pets", text: $viewModel.name)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Icon") {
                    iconGrid
                }
                
                Section("Color") {
                    colorGrid
                }
                
                Section("Preview") {
                    previewView
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    saveButton
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Duplicate Color", isPresented: $viewModel.showColorWarning) {
                Button("Choose Different", role: .cancel) { }
                Button("Use Anyway") {
                    viewModel.confirmSaveDespiteColorWarning()
                    Task {
                        if await viewModel.save() {
                            HapticManager.notification(.success)
                            dismiss()
                        }
                    }
                }
            } message: {
                Text(viewModel.colorWarningMessage)
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext, allCategories: allCategories)
            }
        }
    }
    
    @ViewBuilder
    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
            ForEach(CategoryEditorViewModel.iconOptions, id: \.self) { icon in
                Button {
                    HapticManager.impact(.light)
                    viewModel.selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(viewModel.selectedIcon == icon ? Color(hex: viewModel.selectedColor) : .secondary)
                        .frame(width: 44, height: 44)
                        .background(viewModel.selectedIcon == icon ? Color(hex: viewModel.selectedColor).opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var colorGrid: some View {
        if let conflict = viewModel.colorConflictCategory {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppColors.warning)
                    .font(.caption)
                Text("Also used by \"\(conflict)\"")
                    .font(.caption)
                    .foregroundStyle(AppColors.warning)
            }
        }
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
            ForEach(CategoryEditorViewModel.colorOptions, id: \.self) { color in
                Button {
                    HapticManager.impact(.light)
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
    
    @ViewBuilder
    private var previewView: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.selectedIcon)
                .font(.title2)
                .foregroundStyle(Color(hex: viewModel.selectedColor))
                .frame(width: 36)
            
            Text(viewModel.name.isEmpty ? "Category Name" : viewModel.name)
                .font(.body)
                .foregroundStyle(viewModel.name.isEmpty ? .secondary : .primary)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var saveButton: some View {
        if viewModel.isSaving {
            ProgressView()
        } else {
            Button("Add") {
                Task {
                    if await viewModel.save() {
                        HapticManager.notification(.success)
                        dismiss()
                    }
                }
            }
            .fontWeight(.semibold)
            .disabled(viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}

// MARK: - Edit Category Sheet

struct EditCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: EditCategoryViewModel
    
    init(category: CustomCategory, allCategories: [CustomCategory]) {
        _viewModel = State(wrappedValue: EditCategoryViewModel(category: category, allCategories: allCategories))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("Category name", text: $viewModel.name)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Icon") {
                    iconGrid
                }
                
                Section("Color") {
                    colorGrid
                }
                
                Section("Preview") {
                    previewView
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    saveButton
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Duplicate Color", isPresented: $viewModel.showColorWarning) {
                Button("Choose Different", role: .cancel) { }
                Button("Use Anyway") {
                    viewModel.confirmSaveDespiteColorWarning()
                    if viewModel.save() {
                        HapticManager.notification(.success)
                        dismiss()
                    }
                }
            } message: {
                Text(viewModel.colorWarningMessage)
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
        }
    }
    
    @ViewBuilder
    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
            ForEach(CategoryEditorViewModel.iconOptions, id: \.self) { icon in
                Button {
                    HapticManager.impact(.light)
                    viewModel.selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(viewModel.selectedIcon == icon ? Color(hex: viewModel.selectedColor) : .secondary)
                        .frame(width: 44, height: 44)
                        .background(viewModel.selectedIcon == icon ? Color(hex: viewModel.selectedColor).opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var colorGrid: some View {
        if let conflict = viewModel.colorConflictCategory {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppColors.warning)
                    .font(.caption)
                Text("Also used by \"\(conflict)\"")
                    .font(.caption)
                    .foregroundStyle(AppColors.warning)
            }
        }
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
            ForEach(CategoryEditorViewModel.colorOptions, id: \.self) { color in
                Button {
                    HapticManager.impact(.light)
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
    
    @ViewBuilder
    private var previewView: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.selectedIcon)
                .font(.title2)
                .foregroundStyle(Color(hex: viewModel.selectedColor))
                .frame(width: 36)
            
            Text(viewModel.name.isEmpty ? "Category Name" : viewModel.name)
                .font(.body)
                .foregroundStyle(viewModel.name.isEmpty ? .secondary : .primary)
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var saveButton: some View {
        Button("Save") {
            if viewModel.save() {
                HapticManager.notification(.success)
                dismiss()
            }
        }
        .fontWeight(.semibold)
        .disabled(viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}

#Preview {
    NavigationStack {
        ManageCategoriesView()
    }
    .modelContainer(for: [CustomCategory.self])
}
