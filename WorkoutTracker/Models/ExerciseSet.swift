import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var id: UUID
    var weight: Double
    var reps: Int
    var timestamp: Date
    
    var exercise: Exercise?
    var workoutSession: WorkoutSession?
    
    init(weight: Double, reps: Int, exercise: Exercise, workoutSession: WorkoutSession) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.timestamp = Date()
        self.exercise = exercise
        self.workoutSession = workoutSession
    }
    
    /// Display string for this set
    var displayString: String {
        let weightString = weight.formatted(.number.precision(.fractionLength(0...1)))
        return "\(weightString) lbs × \(reps) reps"
    }
    
    /// Check if this set is a personal record for the exercise
    var isPersonalRecord: Bool {
        guard let exercise = exercise else { return false }
        
        let thisVolume = weight * Double(reps)
        
        for otherSet in exercise.sets where otherSet.id != self.id {
            let otherVolume = otherSet.weight * Double(otherSet.reps)
            
            if otherVolume > thisVolume {
                return false
            }
            
            // Tie-breaker: If volumes are equal, higher reps win
            if otherVolume == thisVolume && otherSet.reps > reps {
                return false
            }
        }
        
        return reps > 0
    }
}
