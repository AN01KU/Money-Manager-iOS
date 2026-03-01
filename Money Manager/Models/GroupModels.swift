import Foundation
import SwiftData

@Model
final class SplitGroupModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdBy: UUID
    var createdAt: String
    
    @Relationship(deleteRule: .cascade, inverse: \GroupMemberModel.group)
    var members: [GroupMemberModel] = []
    
    @Relationship(deleteRule: .cascade, inverse: \GroupExpenseModel.group)
    var expenses: [GroupExpenseModel] = []
    
    init(id: UUID, name: String, createdBy: UUID, createdAt: String) {
        self.id = id
        self.name = name
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

@Model
final class GroupMemberModel {
    @Attribute(.unique) var id: UUID
    var email: String
    var username: String
    var createdAt: String
    
    var group: SplitGroupModel?
    
    init(id: UUID, email: String, username: String, createdAt: String) {
        self.id = id
        self.email = email
        self.username = username
        self.createdAt = createdAt
    }
}

@Model
final class GroupExpenseModel {
    @Attribute(.unique) var id: UUID
    var expenseDescription: String
    var category: String
    var totalAmount: Double
    var paidBy: UUID
    var createdAt: String
    var splitsData: Data?
    
    var group: SplitGroupModel?
    
    init(id: UUID, description: String, category: String, totalAmount: Double, paidBy: UUID, createdAt: String) {
        self.id = id
        self.expenseDescription = description
        self.category = category
        self.totalAmount = totalAmount
        self.paidBy = paidBy
        self.createdAt = createdAt
    }
}

@Model
final class GroupBalanceModel {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var amount: Double
    
    var group: SplitGroupModel?
    
    init(id: UUID = UUID(), userId: UUID, amount: Double, group: SplitGroupModel? = nil) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.group = group
    }
}
