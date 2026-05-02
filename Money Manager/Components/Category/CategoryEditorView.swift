import SwiftUI

struct CategoryEditorView: View {
    @Binding var name: String
    @Binding var selectedIcon: String
    @Binding var selectedColor: String
    let colorConflictCategory: String?
    let onSelectIcon: (String) -> Void
    let onSelectColor: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.UI.spacing20) {
                nameCard
                iconCard
                colorCard
                previewCard
            }
            .padding(.horizontal, AppConstants.UI.padding)
            .padding(.top, AppConstants.UI.spacing12)
            .padding(.bottom, AppConstants.UI.spacingXL)
        }
        .background(AppColors.background)
        .dismissKeyboardOnScroll()
    }

    // MARK: - Name

    private var nameCard: some View {
        EditorSection(header: nil) {
            VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
                Text("Name")
                    .font(AppTypography.subhead)
                    .foregroundStyle(AppColors.label2)
                TextField("e.g., Subscriptions, Pets", text: $name)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.label)
                    .textInputAutocapitalization(.words)
            }
            .padding(AppConstants.UI.padding)
        }
    }

    // MARK: - Icon grid

    private var iconCard: some View {
        EditorSection(header: "ICON") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: AppConstants.UI.spacing12), count: 6),
                spacing: AppConstants.UI.spacing12
            ) {
                ForEach(CategoryEditorViewModel.iconOptions, id: \.self) { icon in
                    Button { onSelectIcon(icon) } label: {
                        let selected = selectedIcon == icon
                        let tint = Color(hex: selectedColor)
                        ZStack {
                            RoundedRectangle(cornerRadius: AppConstants.UI.radius10)
                                .fill(selected ? tint : tint.opacity(0.12))
                                .frame(width: 44, height: 44)
                            AppIcon(name: icon, size: 22,
                                    color: selected ? .white : tint)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppConstants.UI.padding)
        }
    }

    // MARK: - Color grid

    private var colorCard: some View {
        EditorSection(header: "COLOR") {
            VStack(spacing: AppConstants.UI.spacing12) {
                if let conflict = colorConflictCategory {
                    HStack(spacing: 6) {
                        AppIcon(name: AppIcons.UI.warningIcon, size: 14, color: AppColors.warning)
                        Text("Also used by \"\(conflict)\"")
                            .font(AppTypography.caption1)
                            .foregroundStyle(AppColors.warning)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                let palette = AppIcons.CategoryColor.palette
                let columns = Array(repeating: GridItem(.flexible(), spacing: AppConstants.UI.spacing12), count: 8)
                LazyVGrid(columns: columns, spacing: AppConstants.UI.spacing12) {
                    ForEach(palette, id: \.hex) { entry in
                        Button { onSelectColor(entry.hex) } label: {
                            Circle()
                                .fill(entry.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor.lowercased() == entry.hex.lowercased() ? 2.5 : 0)
                                        .padding(-3)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(AppConstants.UI.padding)
        }
    }

    // MARK: - Preview

    private var previewCard: some View {
        EditorSection(header: "PREVIEW") {
            HStack(spacing: AppConstants.UI.spacing12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: selectedColor).opacity(0.15))
                        .frame(width: AppConstants.UI.iconBadgeSize, height: AppConstants.UI.iconBadgeSize)
                    AppIcon(name: selectedIcon,
                            size: AppConstants.UI.iconBadgeSize * 0.52,
                            color: Color(hex: selectedColor))
                }
                Text(name.isEmpty ? "Category Name" : name)
                    .font(AppTypography.body)
                    .foregroundStyle(name.isEmpty ? AppColors.label2 : AppColors.label)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppConstants.UI.padding)
        }
    }
}

// MARK: - Section wrapper

private struct EditorSection<Content: View>: View {
    let header: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.UI.spacingSM) {
            if let header {
                Text(header)
                    .font(AppTypography.footnote)
                    .fontWeight(.semibold)
                    .tracking(AppTypography.trackingFootnote)
                    .foregroundStyle(AppColors.label2)
                    .padding(.leading, AppConstants.UI.spacingXS)
            }
            content
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
        }
    }
}
