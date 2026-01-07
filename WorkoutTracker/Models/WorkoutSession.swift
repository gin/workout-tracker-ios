import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var isActive: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.workoutSession)
    var sets: [ExerciseSet]
    
    init(date: Date = Date(), isActive: Bool = true) {
        self.id = UUID()
        self.date = date
        self.isActive = isActive
        self.sets = []
    }
    

    
    /// Unique exercises in this workout session, ordered by first set time
    var exercises: [Exercise] {
        let activeSets = sets.filter { !$0.isDeleted }
        let grouped = Dictionary(grouping: activeSets) { $0.exercise! }
        return grouped.keys.sorted { exercise1, exercise2 in
            let firstSet1 = grouped[exercise1]?.min(by: { $0.timestamp < $1.timestamp })
            let firstSet2 = grouped[exercise2]?.min(by: { $0.timestamp < $1.timestamp })
            return (firstSet1?.timestamp ?? Date.distantPast) < (firstSet2?.timestamp ?? Date.distantPast)
        }
    }
}
