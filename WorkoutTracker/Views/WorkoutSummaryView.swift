import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSession> { $0.isActive == true })
    private var activeWorkouts: [WorkoutSession]
    @State private var navigateToSession: WorkoutSession?
    
    let workoutSession: WorkoutSession
    
    private var hasActiveWorkout: Bool {
        !activeWorkouts.isEmpty
    }
    
    private var setsByExerciseID: [PersistentIdentifier: [ExerciseSet]] {
        // Break up complex generic chain to help the type-checker
        let nonDeleted: [ExerciseSet] = workoutSession.sets.filter { !$0.isDeleted }

        // Build pairs of (key, set) where key is the exercise id if present, otherwise the set's own persistent id
        let keyed: [(PersistentIdentifier, ExerciseSet)] = nonDeleted.map { set in
            let key: PersistentIdentifier = set.exercise?.id ?? set.persistentModelID
            return (key, set)
        }

        // Group sets by key
        var grouped: [PersistentIdentifier: [ExerciseSet]] = [:]
        for (key, set) in keyed {
            grouped[key, default: []].append(set)
        }

        // Sort each group's sets by timestamp
        for key in grouped.keys {
            grouped[key]?.sort { $0.timestamp < $1.timestamp }
        }

        return grouped
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Workout Name", text: Binding(
                            get: { workoutSession.name },
                            set: { workoutSession.name = $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.primary)
                    }
                    
                    HStack {
                        Text("Date")
                        Spacer()
                        let formattedDate: String = workoutSession.date.formatted(.dateTime.weekday().month().day())
                        Text(formattedDate)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Total Sets")
                        Spacer()
                        Text("\(workoutSession.sets.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Exercises")
                        Spacer()
                        Text("\(workoutSession.exercises.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Workout Summary")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
                
                ForEach(workoutSession.exercises) { exercise in
                    let exerciseName: String = exercise.name
                    let exerciseSets = setsByExerciseID[exercise.id] ?? []
                    Section(exerciseName) {
                        ForEach(Array(exerciseSets.enumerated()), id: \.element.id) { index, set in
                            HStack {
                                Text("Set \(index + 1)")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(set.displayString)
                                    .fontWeight(.medium)
                                if set.isPersonalRecord {
                                    Text("🏆")
                                }
                            }
                        }

                        if let pr = exercise.personalRecord {
                            let weightString: String = pr.weight.formatted(.number.precision(.fractionLength(0...1)))
                            let repsString: String = "\(pr.reps)"
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Personal Best")
                                        .foregroundStyle(.orange)
                                    Text(exercise.personalRecordDateDisplay)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(weightString) lbs × \(repsString) reps")
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        createNewWorkoutFromSummary()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("Reuse Workout")
                        }
                    }
                    .disabled(hasActiveWorkout)
                    .accessibilityIdentifier("newFromSummaryButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(item: $navigateToSession) { session in
                ActiveWorkoutView(workoutSession: session) {
                    dismiss()
                }
            }
        }
    }
    
    private func createNewWorkoutFromSummary() {
        let newSession = WorkoutSession(name: workoutSession.name, isActive: true)
        modelContext.insert(newSession)
        
        // Get all exercises from the source session in their original order
        let sourceExercises: [Exercise] = workoutSession.exercises
        
        // Add exercises as templates (no sets duplicated - user starts fresh)
        newSession.templateExercises = sourceExercises
        
        // Navigate to the new session
        navigateToSession = newSession
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, WorkoutSession.self, ExerciseSet.self, configurations: config)
    
    let session = WorkoutSession(isActive: false)
    container.mainContext.insert(session)
    
    let exercise = Exercise(name: "Bench Press")
    container.mainContext.insert(exercise)
    
    let set1 = ExerciseSet(weight: 135, reps: 10, exercise: exercise, workoutSession: session)
    container.mainContext.insert(set1)
    let set2 = ExerciseSet(weight: 155, reps: 8, exercise: exercise, workoutSession: session)
    container.mainContext.insert(set2)
    
    return WorkoutSummaryView(workoutSession: session)
        .modelContainer(container)
}

