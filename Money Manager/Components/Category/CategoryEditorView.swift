import SwiftUI

struct CategoryEditorView: View {
    @Binding var name: String
    @Binding var selectedIcon: String
    @Binding var selectedColor: String
    let colorConflictCategory: String?
    let onSelectIcon: (String) -> Void
    let onSelectColor: (String) -> Void
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("e.g., Subscriptions, Pets", text: $name)
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
        .dismissKeyboardOnScroll()
    }
    
    @ViewBuilder
    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
            ForEach(CategoryEditorViewModel.iconOptions, id: \.self) { icon in
                Button {
                    onSelectIcon(icon)
                } label: {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                        .frame(width: 44, height: 44)
                        .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var colorGrid: some View {
        if let conflict = colorConflictCategory {
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
                    onSelectColor(color)
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
    
    @ViewBuilder
    private var previewView: some View {
        HStack(spacing: 12) {
            Image(systemName: selectedIcon)
                .font(.title2)
                .foregroundStyle(Color(hex: selectedColor))
                .frame(width: 36)
            
            Text(name.isEmpty ? "Category Name" : name)
                .font(.body)
                .foregroundStyle(name.isEmpty ? .secondary : .primary)
        }
        .padding(.vertical, 4)
    }
}
