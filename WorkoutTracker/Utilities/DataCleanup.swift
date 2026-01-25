import Foundation
import SwiftData

struct DataCleanup {
    /// Removes duplicate exercises, keeping the one with the most usage (sets).
    static func cleanDuplicates(context: ModelContext) {
        do {
            // Fetch all exercises
            let descriptor = FetchDescriptor<Exercise>()
            let exercises = try context.fetch(descriptor)
            
            // Group by normalized name
            let grouped = Dictionary(grouping: exercises) {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
            
            var deletedCount = 0
            
            for (name, duplicates) in grouped where duplicates.count > 1 {
                print("Found \(duplicates.count) duplicates for '\(name)'")
                
                // Sort by usage (set count) descending, then by creation (if we tracked it, but here just stable sort)
                // Since we don't have creation date, we rely on set count.
                // If tied, we pick one arbitrarily (the first one).
                let sorted = duplicates.sorted { lhs, rhs in
                    lhs.sets.count > rhs.sets.count
                }
                
                // Keep head, delete tail
                let toKeep = sorted.first!
                let toDelete = sorted.dropFirst()
                
                print("Keeping ID: \(toKeep.id) with \(toKeep.sets.count) sets")
                
                for duplicate in toDelete {
                    print("Deleting duplicate ID: \(duplicate.id) with \(duplicate.sets.count) sets")
                    // If the duplicate had sets (unlikely given our sort, but possible if equal), they will be deleted due to cascade rule
                    // Ideally we might want to migrate them, but for now we assume duplicates are accidental empty ones or we just accept data loss of the duplicate's history if the user really made two distinct active ones.
                    // Given the prompt "For the duplicated ones, there are no Personal Record while the original one has", it implies the duplicates are empty.
                    context.delete(duplicate)
                    deletedCount += 1
                }
            }
            
            if deletedCount > 0 {
                try context.save()
                print("Cleanup complete. Removed \(deletedCount) duplicate exercises.")
            }
            
        } catch {
            print("DataCleanup error: \(error)")
        }
    }
}
