import Testing
import SwiftData
import Foundation
@testable import WorkoutTracker

@MainActor
struct WorkoutTrackerTests {
    
    // MARK: - Helper
    
    private func createContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Exercise.self, ExerciseSet.self, WorkoutSession.self, configurations: config)
    }
    
    // MARK: - ExerciseSet Tests
    
    @Test
    func testExerciseSetDisplayString() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Test Exercise")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        let wholeNumberSet = ExerciseSet(weight: 135.0, reps: 5, exercise: exercise, workoutSession: session)
        let decimalSet = ExerciseSet(weight: 12.5, reps: 10, exercise: exercise, workoutSession: session)
        
        #expect(wholeNumberSet.displayString == "135 lbs × 5 reps")
        #expect(decimalSet.displayString == "12.5 lbs × 10 reps")
    }
    
    @Test
    func testManualPRLogic_Volume() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Squat")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        // Set 1: 100 * 5 = 500 volume
        let set1 = ExerciseSet(weight: 100, reps: 5, exercise: exercise, workoutSession: session)
        // Set 2: 100 * 6 = 600 volume (Winner)
        let set2 = ExerciseSet(weight: 100, reps: 6, exercise: exercise, workoutSession: session)
        
        container.mainContext.insert(set1)
        container.mainContext.insert(set2)
        
        #expect(set1.isPersonalRecord == false)
        #expect(set2.isPersonalRecord == true)
        
        let pr = try #require(exercise.personalRecord)
        #expect(pr.weight == 100)
        #expect(pr.reps == 6)
    }
    
    @Test
    func testManualPRLogic_TieBreaker_Reps() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Bench")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        // Set 1: 100 * 10 = 1000 volume
        let set1 = ExerciseSet(weight: 100, reps: 10, exercise: exercise, workoutSession: session)
        // Set 2: 200 * 5 = 1000 volume (Tie in volume, but fewer reps)
        let set2 = ExerciseSet(weight: 200, reps: 5, exercise: exercise, workoutSession: session)
        
        container.mainContext.insert(set1)
        container.mainContext.insert(set2)
        
        // Logic: If volumes are equal, higher reps win.
        // set1 is the "winner" because 10 reps > 5 reps.
        
        #expect(set1.isPersonalRecord == true)
        #expect(set2.isPersonalRecord == false)
        
        let pr = try #require(exercise.personalRecord)
        #expect(pr.weight == 100)
        #expect(pr.reps == 10)
    }
    
    @Test
    func testBodyweightPR() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Pullups")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        // Set 1: 0 * 5 = 0
        let set1 = ExerciseSet(weight: 0, reps: 5, exercise: exercise, workoutSession: session)
        // Set 2: 0 * 8 = 0 (Tie volume, higher reps wins)
        let set2 = ExerciseSet(weight: 0, reps: 8, exercise: exercise, workoutSession: session)
        
        container.mainContext.insert(set1)
        container.mainContext.insert(set2)
        
        #expect(set1.isPersonalRecord == false)
        #expect(set2.isPersonalRecord == true)
        
        let pr = try #require(exercise.personalRecord)
        #expect(pr.weight == 0)
        #expect(pr.reps == 8)
    }
    
    // MARK: - Deletion Logic Tests
    
    @Test
    func testDeletedSetsAreignoredInPR() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Deadlift")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        // Set 1: Best set
        let set1 = ExerciseSet(weight: 315, reps: 5, exercise: exercise, workoutSession: session)
        // Set 2: Okay set
        let set2 = ExerciseSet(weight: 225, reps: 5, exercise: exercise, workoutSession: session)
        
        container.mainContext.insert(set1)
        container.mainContext.insert(set2)
        
        // Confirm set1 is PR
        #expect(set1.isPersonalRecord == true)
        #expect(set2.isPersonalRecord == false)
        
        // Delete set1
        modelContext(from: container).delete(set1)
        
        let pr = try #require(exercise.personalRecord)
        #expect(pr.weight == 225)
        #expect(pr.reps == 5)
        
        #expect(set1.isPersonalRecord == false)
        #expect(set2.isPersonalRecord == true)
    }
    
    @Test
    func testWorkoutSessionGroupingIgnoresDeleted() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Row")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        let set1 = ExerciseSet(weight: 100, reps: 10, exercise: exercise, workoutSession: session)
        container.mainContext.insert(set1)
        
        // Should have 1 exercise
        #expect(session.exercises.count == 1)
        #expect(session.exercises.first?.name == "Row")
        
        // Delete the set
        modelContext(from: container).delete(set1)
        
        // Should have 0 exercises now because the session filters out deleted sets
        #expect(session.exercises.isEmpty)
    }
    
    // Helper to get context easily
    private func modelContext(from container: ModelContainer) -> ModelContext {
        container.mainContext
    }
}
