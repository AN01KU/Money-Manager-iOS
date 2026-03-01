//
//  KeychainService.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 15/02/26.
//

import Foundation
import SwiftData

@MainActor
final class KeychainService {
    static let shared = KeychainService()
    
    private var modelContainer: ModelContainer?
    
    private init() {}
    
    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
    }
    
    @discardableResult
    func saveToken(_ token: String) -> Bool {
        guard let context = modelContainer?.mainContext else { return false }
        
        deleteToken()
        
        let authToken = AuthToken(token: token)
        context.insert(authToken)
        
        return (try? context.save()) != nil
    }
    
    func getToken() -> String? {
        guard let context = modelContainer?.mainContext else { return nil }
        
        let descriptor = FetchDescriptor<AuthToken>()
        return try? context.fetch(descriptor).first?.token
    }
    
    @discardableResult
    func deleteToken() -> Bool {
        guard let context = modelContainer?.mainContext else { return false }
        
        let descriptor = FetchDescriptor<AuthToken>()
        if let token = try? context.fetch(descriptor).first {
            context.delete(token)
            return (try? context.save()) != nil
        }
        return false
    }
    
    var isLoggedIn: Bool {
        getToken() != nil
    }
}
