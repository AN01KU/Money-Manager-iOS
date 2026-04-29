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
                        .font(AppTypography.subhead)
                        .foregroundStyle(AppColors.label2)
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
                    ZStack {
                        RoundedRectangle(cornerRadius: AppConstants.UI.radius10)
                            .fill(selectedIcon == icon
                                  ? Color(hex: selectedColor)
                                  : Color(hex: selectedColor).opacity(0.12))
                            .frame(width: 44, height: 44)
                        AppIcon(name: icon, size: 22,
                                color: selectedIcon == icon ? .white : Color(hex: selectedColor))
                    }
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
                AppIcon(name: AppIcons.UI.warningIcon, size: 14, color: AppColors.warning)
                Text("Also used by \"\(conflict)\"")
                    .font(AppTypography.caption1)
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
        HStack(spacing: AppConstants.UI.spacing12) {
            ZStack {
                RoundedRectangle(cornerRadius: AppConstants.UI.radius10)
                    .fill(Color(hex: selectedColor))
                    .frame(width: AppConstants.UI.iconBadgeSize, height: AppConstants.UI.iconBadgeSize)
                AppIcon(name: selectedIcon, size: AppConstants.UI.iconBadgeSize * 0.50, color: .white)
            }
            Text(name.isEmpty ? "Category Name" : name)
                .font(AppTypography.body)
                .foregroundStyle(name.isEmpty ? AppColors.label2 : AppColors.label)
        }
        .padding(.vertical, 4)
    }
}
