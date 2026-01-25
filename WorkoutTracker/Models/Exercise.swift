import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet]
    
    init(name: String) {
        self.id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sets = []
    }
    
    /// Returns the personal record as (weight, reps) tuple, or nil if no sets exist
    var personalRecord: (weight: Double, reps: Int)? {
        guard !sets.isEmpty else { return nil }
        
        // Find the set with the highest weight × reps (estimated 1RM proxy)
        // If volumes are tied, higher reps win
        let bestSet = sets.filter { !$0.isDeleted }.max { lhs, rhs in
            let lhsVolume = lhs.weight * Double(lhs.reps)
            let rhsVolume = rhs.weight * Double(rhs.reps)
            
            if lhsVolume != rhsVolume {
                return lhsVolume < rhsVolume
            }
            return lhs.reps < rhs.reps
        }
        
        guard let best = bestSet else { return nil }
        return (weight: best.weight, reps: best.reps)
    }
    
    /// Formatted personal record string for display
    var personalRecordDisplay: String {
        guard let pr = personalRecord else { return "No history" }
        let weightString = pr.weight.formatted(.number.precision(.fractionLength(0...1)))
        return "\(weightString) × \(pr.reps)"
    }
}
