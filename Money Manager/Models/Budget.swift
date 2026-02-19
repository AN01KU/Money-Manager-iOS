//
//  Budget.swift
//  Money Manager
//
//  Created by Ankush Ganesh on 13/01/26.
//

import Foundation

struct Budget {
    let monthlyLimit: Double
    let spent: Double
    let month: Date
    
    var percentage: Int {
        guard monthlyLimit > 0 else { return 0 }
        return Int((spent / monthlyLimit) * 100.0)
    }
    
    var remaining: Double {
        monthlyLimit - spent
    }
}
