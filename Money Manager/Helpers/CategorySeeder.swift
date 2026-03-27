import Foundation
import SwiftData

struct CategorySeeder {
    /// Seeds all predefined categories as CustomCategory records if they haven't been created yet.
    /// Call this once on app launch.
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<CustomCategory>(
            predicate: #Predicate { $0.isPredefined == true }
        )
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else {
            AppLogger.data.debug("CategorySeeder: skipped, \(existingCount) predefined categories already exist")
            return
        }

        for predefined in PredefinedCategory.allCases {
            let category = CustomCategory(
                name: predefined.rawValue,
                icon: predefined.icon,
                color: predefined.defaultColorHex,
                isPredefined: true,
                predefinedKey: predefined.key
            )
            context.insert(category)
        }

        do {
            try context.save()
            AppLogger.data.info("CategorySeeder: seeded \(PredefinedCategory.allCases.count) predefined categories")
        } catch {
            AppLogger.data.error("CategorySeeder: failed to save seeded categories: \(error)")
        }
    }
}
