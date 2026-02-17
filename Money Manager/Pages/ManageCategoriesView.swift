import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomCategory.name) private var customCategories: [CustomCategory]
    
    @State private var showAddCategory = false
    
    private var visibleCategories: [CustomCategory] {
        customCategories.filter { !$0.isHidden }
    }
    
    private var hiddenCategories: [CustomCategory] {
        customCategories.filter { $0.isHidden }
    }
    
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
            
            if !visibleCategories.isEmpty {
                Section("Your Categories") {
                    ForEach(visibleCategories) { category in
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
                            let category = visibleCategories[index]
                            category.isHidden = true
                            category.updatedAt = Date()
                        }
                        try? modelContext.save()
                    }
                }
            }
            
            if !hiddenCategories.isEmpty {
                Section("Hidden Categories") {
                    ForEach(hiddenCategories) { category in
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .foregroundColor(Color(hex: category.color).opacity(0.5))
                                .frame(width: 28)
                            
                            Text(category.name)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Restore") {
                                category.isHidden = false
                                category.updatedAt = Date()
                                try? modelContext.save()
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
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.teal)
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet()
        }
    }
}

struct AddCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var selectedIcon = "tag.circle.fill"
    @State private var selectedColor = "#4ECDC4"
    
    private let iconOptions = [
        "tag.circle.fill", "cart.circle.fill", "heart.circle.fill",
        "star.circle.fill", "flame.circle.fill", "drop.circle.fill",
        "leaf.circle.fill", "pawprint.circle.fill", "cup.and.saucer.fill",
        "tshirt.fill", "dumbbell.fill", "paintbrush.circle.fill",
        "music.note", "film.circle.fill", "bicycle.circle.fill",
        "bus.fill", "fuelpump.circle.fill", "wrench.and.screwdriver.fill",
        "camera.circle.fill", "phone.circle.fill", "wifi.circle.fill",
        "banknote.fill", "giftcard.fill", "stroller.fill"
    ]
    
    private let colorOptions = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA15E", "#BC6C25", "#8E44AD",
        "#3498DB", "#E74C3C", "#F39C12", "#E91E63",
        "#2ECC71", "#1ABC9C", "#9B59B6", "#34495E"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("e.g., Subscriptions, Pets", text: $name)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.12) : Color.clear)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2.5 : 0)
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
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundColor(Color(hex: selectedColor))
                            .frame(width: 36)
                        
                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.body)
                            .foregroundColor(name.isEmpty ? .secondary : .primary)
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
                    Button("Add") {
                        saveCategory()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveCategory() {
        let category = CustomCategory(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon,
            color: selectedColor
        )
        modelContext.insert(category)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ManageCategoriesView()
    }
    .modelContainer(for: [CustomCategory.self])
}
