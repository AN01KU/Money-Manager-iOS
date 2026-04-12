//
//  TestConfig.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 22/03/26.
//

import Foundation

public func getTestAppLaunchArguments(_ isForOnboardingFlow: Bool = false) -> [String] {
    let args: [LaunchArguments] = [
        .isUITesting,
        !isForOnboardingFlow ? .skipOnboarding: .resetOnboarding,
        .useTestData,
        .useMockServices
    ]
    
    return args.map { $0.rawValue }
}
