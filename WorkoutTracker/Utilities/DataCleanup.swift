import Foundation
import SwiftData

struct DataCleanup {
    /// Removes duplicate exercises, keeping the one with the most usage (sets).
    /// Runs asynchronously to avoid blocking app launch.
    @MainActor
    static func cleanDuplicatesAsync(context: ModelContext) {
        Task.detached(priority: .background) {
            await MainActor.run {
                cleanDuplicates(context: context)
            }
        }
    }
    
    /// Synchronous cleanup - use cleanDuplicatesAsync for non-blocking execution
    @MainActor
    static func cleanDuplicates(context: ModelContext) {
        do {
            // Fetch all exercises
            let descriptor = FetchDescriptor<Exercise>()
            let exercises = try context.fetch(descriptor)
            
            // Early exit if no exercises
            guard !exercises.isEmpty else { return }
            
            // Group by normalized name
            let grouped = Dictionary(grouping: exercises) {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
            
            // Early exit if no duplicates (all groups have exactly 1 item)
            let hasDuplicates = grouped.values.contains { $0.count > 1 }
            guard hasDuplicates else { return }
            
            var deletedCount = 0
            
            for (name, duplicates) in grouped where duplicates.count > 1 {
                print("Found \(duplicates.count) duplicates for '\(name)'")
                
                // Sort by usage (set count) descending
                let sorted = duplicates.sorted { lhs, rhs in
                    lhs.sets.count > rhs.sets.count
                }
                
                // Keep head, delete tail
                let toKeep = sorted.first!
                let toDelete = sorted.dropFirst()
                
                print("Keeping ID: \(toKeep.id) with \(toKeep.sets.count) sets")
                
                for duplicate in toDelete {
                    print("Deleting duplicate ID: \(duplicate.id) with \(duplicate.sets.count) sets")
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
