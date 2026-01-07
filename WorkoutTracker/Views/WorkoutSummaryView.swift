import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    
    let workoutSession: WorkoutSession
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(workoutSession.date, format: .dateTime.weekday().month().day())
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
                }
                
                ForEach(workoutSession.exercises) { exercise in
                    Section(exercise.name) {
                        let exerciseSets = workoutSession.sets
                            .filter { $0.exercise?.id == exercise.id && !$0.isDeleted }
                            .sorted { $0.timestamp < $1.timestamp }
                        
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
                        
                        // Show PR comparison
                        if let pr = exercise.personalRecord {
                            HStack {
                                Label("Personal Best", systemImage: "trophy.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Spacer()
                                let weightString = pr.weight.formatted(.number.precision(.fractionLength(0...1)))
                                Text("\(weightString) lbs × \(pr.reps) reps")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
    let set2 = ExerciseSet(weight: 155, reps: 8, exercise: exercise, workoutSession: session)
    container.mainContext.insert(set1)
    container.mainContext.insert(set2)
    
    return WorkoutSummaryView(workoutSession: session)
        .modelContainer(container)
}
