//
//  PendingChangeDraft.swift
//  Money Manager
//

import Foundation

struct PendingChangeDraft {
    let entityType: EntityType
    let entityID: UUID
    let action: ChangeAction
    let endpoint: String
    let httpMethod: HTTPMethod
    let payload: Data?
}
