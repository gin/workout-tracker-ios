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
    
    // MARK: - Personal Record Date Display Tests
    
    @Test
    func testPersonalRecordDateDisplay_Today() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Bench")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        // Create a set with today's timestamp
        let set1 = ExerciseSet(weight: 100, reps: 10, exercise: exercise, workoutSession: session)
        container.mainContext.insert(set1)
        
        #expect(exercise.personalRecordDateDisplay == "Today")
    }
    
    @Test
    func testPersonalRecordDateDisplay_OneDayAgo() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Squat")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        let set1 = ExerciseSet(weight: 200, reps: 5, exercise: exercise, workoutSession: session)
        // Set timestamp to yesterday
        set1.timestamp = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        container.mainContext.insert(set1)
        
        #expect(exercise.personalRecordDateDisplay == "1 day ago")
    }
    
    @Test
    func testPersonalRecordDateDisplay_MultipleDaysAgo() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Deadlift")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        let set1 = ExerciseSet(weight: 300, reps: 3, exercise: exercise, workoutSession: session)
        // Set timestamp to 15 days ago
        set1.timestamp = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        container.mainContext.insert(set1)
        
        #expect(exercise.personalRecordDateDisplay == "15 days ago")
    }
    
    @Test
    func testPersonalRecordDateDisplay_OldDate() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Press")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        let set1 = ExerciseSet(weight: 150, reps: 8, exercise: exercise, workoutSession: session)
        // Set timestamp to 60 days ago (>31 days)
        let oldDate = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        set1.timestamp = oldDate
        container.mainContext.insert(set1)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let expectedDate = formatter.string(from: oldDate)
        
        #expect(exercise.personalRecordDateDisplay == expectedDate)
    }
    
    @Test
    func testPersonalRecordDateDisplay_NoSets() throws {
        let container = try createContainer()
        let exercise = Exercise(name: "New Exercise")
        container.mainContext.insert(exercise)
        
        #expect(exercise.personalRecordDateDisplay == "")
    }
    
    // MARK: - Personal Record Display Tests
    
    @Test
    func testPersonalRecordDisplay_FormatsCorrectly() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Curl")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        let set1 = ExerciseSet(weight: 45.5, reps: 12, exercise: exercise, workoutSession: session)
        container.mainContext.insert(set1)
        
        #expect(exercise.personalRecordDisplay == "45.5 × 12")
    }
    
    @Test
    func testPersonalRecordDisplay_NoHistory() throws {
        let container = try createContainer()
        let exercise = Exercise(name: "Brand New Exercise")
        container.mainContext.insert(exercise)
        
        #expect(exercise.personalRecordDisplay == "No history")
    }
    
    // MARK: - Template Exercises Tests
    
    @Test
    func testTemplateExercisesOrdering() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        container.mainContext.insert(session)
        
        // Create exercises
        let benchPress = Exercise(name: "Bench Press")
        let squat = Exercise(name: "Squat")
        let deadlift = Exercise(name: "Deadlift")
        container.mainContext.insert(benchPress)
        container.mainContext.insert(squat)
        container.mainContext.insert(deadlift)
        
        // Add squat as template
        session.templateExercises = [squat, deadlift]
        
        // Log a set for bench press
        let set1 = ExerciseSet(weight: 135, reps: 10, exercise: benchPress, workoutSession: session)
        container.mainContext.insert(set1)
        
        // Exercises should be: bench (has set), then squat, deadlift (templates in order)
        let exercises = session.exercises
        #expect(exercises.count == 3)
        #expect(exercises[0].name == "Bench Press")
        #expect(exercises[1].name == "Squat")
        #expect(exercises[2].name == "Deadlift")
    }
    
    // MARK: - Exercise Name Editing Tests
    
    @Test
    func testExerciseRename_UpdatesAllReferences() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Bench Press")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        // Create multiple sets for the exercise
        let set1 = ExerciseSet(weight: 135, reps: 10, exercise: exercise, workoutSession: session)
        let set2 = ExerciseSet(weight: 185, reps: 5, exercise: exercise, workoutSession: session)
        container.mainContext.insert(set1)
        container.mainContext.insert(set2)
        
        // Verify initial state
        #expect(exercise.name == "Bench Press")
        #expect(set1.exercise?.name == "Bench Press")
        #expect(set2.exercise?.name == "Bench Press")
        
        // Rename exercise
        exercise.name = "Incline Bench Press"
        
        // All references should see the new name
        #expect(exercise.name == "Incline Bench Press")
        #expect(set1.exercise?.name == "Incline Bench Press")
        #expect(set2.exercise?.name == "Incline Bench Press")
    }
    
    @Test
    func testExerciseRename_PreservesPersonalRecord() throws {
        let container = try createContainer()
        let session = WorkoutSession()
        let exercise = Exercise(name: "Squat")
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        
        let prSet = ExerciseSet(weight: 315, reps: 5, exercise: exercise, workoutSession: session)
        container.mainContext.insert(prSet)
        
        // Verify PR before rename
        let prBefore = try #require(exercise.personalRecord)
        #expect(prBefore.weight == 315)
        #expect(prBefore.reps == 5)
        
        // Rename exercise
        exercise.name = "Back Squat"
        
        // PR should still be intact
        let prAfter = try #require(exercise.personalRecord)
        #expect(prAfter.weight == 315)
        #expect(prAfter.reps == 5)
        #expect(exercise.personalRecordDisplay == "315 × 5")
    }
    
    // Helper to get context easily
    private func modelContext(from container: ModelContainer) -> ModelContext {
        container.mainContext
    }
}
