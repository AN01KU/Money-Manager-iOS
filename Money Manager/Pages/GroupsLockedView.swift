//
//  GroupsLockedView.swift
//  Money Manager
//

import SwiftUI

struct GroupsLockedView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("Groups Require Sign In")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Sign in to create groups, split transactions, and settle up with friends.\n\nAny group transactions already on your account will continue to appear in Overview.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Groups")
        }
    }
}
