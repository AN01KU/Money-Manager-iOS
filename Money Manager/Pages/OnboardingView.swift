//
//  OnboardingView.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 10/03/26.
//

import SwiftUI
import Charts

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var getStartedTapped = 0
    @State private var skipTapped = 0
    @State private var nextTapped = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "indianrupeesign.circle.fill",
            title: "Track Expenses",
            description: "Quickly log your daily expenses with categories, descriptions, and timestamps. Stay on top of every rupee you spend.",
            color: .teal
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Set Budgets",
            description: "Create monthly budgets and get real-time progress updates. Know exactly how much you can spend each day.",
            color: .orange
        ),
        OnboardingPage(
            icon: "arrow.clockwise.circle.fill",
            title: "Recurring Expenses",
            description: "Set up recurring expenses so they're automatically tracked. Never forget a subscription or bill again.",
            color: .purple
        ),
        OnboardingPage(
            icon: "square.grid.2x2.fill",
            title: "Custom Categories",
            description: "Organise your spending your way. Create custom categories that match your lifestyle and spending habits.",
            color: .blue
        ),
        OnboardingPage(
            icon: "archivebox.fill",
            title: "Backup & Export",
            description: "Export your data anytime as CSV. Your financial data stays on your device — private and secure.",
            color: .green
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            bottomSection
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Bottom Section
    
    private var bottomSection: some View {
        VStack(spacing: 20) {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? AppColors.accent : Color(.systemGray4))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .accessibilityLabel("Page \(currentPage + 1) of \(pages.count)")
            
            if currentPage == pages.count - 1 {
                Button {
                    getStartedTapped += 1
                    hasCompletedOnboarding = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: getStartedTapped)
                .accessibilityLabel("Get started with Money Manager")
            } else {
                HStack {
                    Button {
                        skipTapped += 1
                        hasCompletedOnboarding = true
                    } label: {
                        Text("Skip")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: skipTapped)
                    .accessibilityLabel("Skip onboarding")
                    
                    Spacer()
                    
                    Button {
                        nextTapped += 1
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Next")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(AppColors.accent)
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: nextTapped)
                    .accessibilityLabel("Next page")
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

#Preview {
    OnboardingView()
}
