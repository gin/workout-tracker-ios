import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var name: String = ""
    var date: Date
    var isActive: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.workoutSession)
    var sets: [ExerciseSet]
    
    /// Exercises added as templates from a previous workout (before any sets are logged)
    var templateExercises: [Exercise]
    
    init(name: String = "", date: Date = Date(), isActive: Bool = true) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.isActive = isActive
        self.sets = []
        self.templateExercises = []
    }
    
    /// Unique exercises in this workout session, ordered by first set time
    /// Includes both exercises with logged sets and template exercises
    var exercises: [Exercise] {
        let activeSets = sets.filter { !$0.isDeleted }
        let grouped = Dictionary(grouping: activeSets) { $0.exercise! }
        
        // Get exercises from sets with their first set timestamp
        var exerciseTimestamps: [Exercise: Date] = [:]
        for (exercise, exerciseSets) in grouped {
            exerciseTimestamps[exercise] = exerciseSets.min(by: { $0.timestamp < $1.timestamp })?.timestamp ?? Date.distantPast
        }
        
        // Add template exercises that don't have any sets yet
        // Use staggered timestamps based on array index to preserve their original order
        for (index, templateExercise) in templateExercises.enumerated() {
            if exerciseTimestamps[templateExercise] == nil {
                // Use distantFuture + index to maintain stable relative ordering
                exerciseTimestamps[templateExercise] = Date.distantFuture.addingTimeInterval(Double(index))
            }
        }
        
        return exerciseTimestamps.keys.sorted { exercise1, exercise2 in
            (exerciseTimestamps[exercise1] ?? Date.distantPast) < (exerciseTimestamps[exercise2] ?? Date.distantPast)
        }
    }
    
    /// Determine smart defaults for a new set of the given exercise
    /// 1. Last set from THIS workout session (for consecutive sets)
    /// 2. Personal Record (for the first set of the session)
    func smartDefaults(for exercise: Exercise) -> (weight: Double, reps: Int)? {
        // Check current session history first
        let sessionSets = sets
            .filter { $0.exercise?.id == exercise.id && !$0.isDeleted }
            .sorted { $0.timestamp > $1.timestamp }
            
        if let lastSessionSet = sessionSets.first {
            return (lastSessionSet.weight, lastSessionSet.reps)
        }
        
        // Fallback to PR
        if let pr = exercise.personalRecord {
            return (pr.weight, pr.reps)
        }
        
        return nil
    }
}
