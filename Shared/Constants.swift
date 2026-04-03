//
//  Constants.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 22/03/26.
//

import Foundation

public enum LaunchArguments: String {
    case isUITesting = "--uitesting"
    case useTestData = "--useTestData"
    case useMockServices = "--useMocks"
    case skipOnboarding = "--skipOnboarding"
    case resetOnboarding = "--resetOnboarding"
    case screenshotMode = "--screenshotMode"
    case testEmail = "--testEmail"
    case testPassword = "--testPassword"
}

public extension ProcessInfo {
    var isUITesting: Bool {
        return arguments.contains(LaunchArguments.isUITesting.rawValue)
    }
    
    var useTestData: Bool {
        return arguments.contains(LaunchArguments.useTestData.rawValue)
    }
    
    var useMockServices: Bool {
        return arguments.contains(LaunchArguments.useMockServices.rawValue) || isRunningTests
    }
    
    var skipOnboarding: Bool {
        return arguments.contains(LaunchArguments.skipOnboarding.rawValue)
    }
    
    var resetOnboarding: Bool {
        return arguments.contains(LaunchArguments.resetOnboarding.rawValue)
    }
    
    var isRunningTests: Bool {
        return environment["XCTestConfigurationFilePath"] != nil
    }

    var isScreenshotMode: Bool {
        return arguments.contains(LaunchArguments.screenshotMode.rawValue)
    }
}
