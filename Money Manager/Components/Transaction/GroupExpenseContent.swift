import SwiftUI

struct GroupExpenseContent: View {
    let groupName: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(groupName ?? "Unknown Group")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("Group expense")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(AppColors.accentLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
