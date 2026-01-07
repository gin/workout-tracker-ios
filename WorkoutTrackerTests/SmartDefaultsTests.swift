import XCTest
import SwiftData
@testable import WorkoutTracker

@MainActor
final class SmartDefaultsTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Exercise.self, WorkoutSession.self, ExerciseSet.self, configurations: config)
        context = container.mainContext
    }
    
    func testSmartDefaults_FirstSetInSession_UsesPersonalRecord() throws {
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)
        
        // Create a previous session with a good set (PR)
        let oldSession = WorkoutSession(date: Date().addingTimeInterval(-86400)) // Yesterday
        context.insert(oldSession)
        
        let prSet = ExerciseSet(weight: 225, reps: 5, exercise: exercise, workoutSession: oldSession)
        context.insert(prSet)
        
        // Current session
        let currentSession = WorkoutSession()
        context.insert(currentSession)
        
        // Check defaults
        let defaults = currentSession.smartDefaults(for: exercise)
        
        XCTAssertNotNil(defaults)
        XCTAssertEqual(defaults?.weight, 225)
        XCTAssertEqual(defaults?.reps, 5)
    }
    
    func testSmartDefaults_SubsequentSetInSession_UsesLastSetFromSession() throws {
        let exercise = Exercise(name: "Bench Press")
        context.insert(exercise)
        
        // PR exists
        let oldSession = WorkoutSession(date: Date().addingTimeInterval(-86400))
        context.insert(oldSession)
        let prSet = ExerciseSet(weight: 225, reps: 5, exercise: exercise, workoutSession: oldSession)
        context.insert(prSet)
        
        // Current session
        let currentSession = WorkoutSession()
        context.insert(currentSession)
        
        // User logs a lighter set first (e.g., warmup)
        let warmupSet = ExerciseSet(weight: 135, reps: 10, exercise: exercise, workoutSession: currentSession)
        // Ensure timestamp is later than PR (though session separation should handle this logic-wise)
        warmupSet.timestamp = Date() 
        context.insert(warmupSet)
        
        // Check defaults - should match warmup, not PR
        let defaults = currentSession.smartDefaults(for: exercise)
        
        XCTAssertNotNil(defaults)
        XCTAssertEqual(defaults?.weight, 135)
        XCTAssertEqual(defaults?.reps, 10)
    }
    
    func testSmartDefaults_NoHistory_ReturnsNil() throws {
        let exercise = Exercise(name: "New Exercise")
        context.insert(exercise)
        
        let currentSession = WorkoutSession()
        context.insert(currentSession)
        
        let defaults = currentSession.smartDefaults(for: exercise)
        
        XCTAssertNil(defaults)
    }
}

