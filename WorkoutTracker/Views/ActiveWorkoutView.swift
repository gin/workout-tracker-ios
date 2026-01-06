import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var workoutSession: WorkoutSession
    
    @State private var showExerciseSearch = false
    @State private var selectedExerciseForSet: Exercise?
    @State private var isConfirmingFinish = false
    
    var body: some View {
        List {
            if workoutSession.exercises.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Exercises Yet",
                        systemImage: "dumbbell",
                        description: Text("Tap the + button to add your first exercise")
                    )
                }
            } else {
                ForEach(workoutSession.exercises) { exercise in
                    Section(exercise.name) {
                        let exerciseSets = workoutSession.sets
                            .filter { $0.exercise?.id == exercise.id }
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
                        .onDelete { indexSet in
                            deleteSet(at: indexSet, from: exerciseSets)
                        }
                        
                        Button {
                            selectedExerciseForSet = exercise
                        } label: {
                            Label("Add Set", systemImage: "plus")
                        }
                    }
                }
            }
        }
        .overlay {
            if isConfirmingFinish {
                Color.black.opacity(0.001) // Nearly transparent but catches taps
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            isConfirmingFinish = false
                        }
                    }
                    .ignoresSafeArea()
            }
        }
        .navigationTitle("Workout")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showExerciseSearch = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                if isConfirmingFinish {
                    SlideToConfirmView(text: "Slide to Finish") {
                        finishWorkout()
                    }
                    .frame(width: 280)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button {
                        if workoutSession.sets.isEmpty {
                            finishWorkout()
                        } else {
                            withAnimation {
                                isConfirmingFinish = true
                            }
                        }
                    } label: {
                        Text(workoutSession.sets.isEmpty ? "Cancel Workout" : "Finish Workout")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                }
            }
        }
        .sheet(isPresented: $showExerciseSearch) {
            ExerciseSearchView(workoutSession: workoutSession) { exercise in
                selectedExerciseForSet = exercise
            }
        }
        .sheet(item: $selectedExerciseForSet) { exercise in
            SetEntrySheet(exercise: exercise, workoutSession: workoutSession)
        }
    }
    
    private func deleteSet(at offsets: IndexSet, from sets: [ExerciseSet]) {
        for index in offsets {
            modelContext.delete(sets[index])
        }
    }
    
    private func finishWorkout() {
        if workoutSession.sets.isEmpty {
            modelContext.delete(workoutSession)
        } else {
            workoutSession.isActive = false
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, WorkoutSession.self, ExerciseSet.self, configurations: config)
    
    let session = WorkoutSession()
    container.mainContext.insert(session)
    
    let exercise = Exercise(name: "Bench Press")
    container.mainContext.insert(exercise)
    
    let set1 = ExerciseSet(weight: 135, reps: 10, exercise: exercise, workoutSession: session)
    let set2 = ExerciseSet(weight: 155, reps: 8, exercise: exercise, workoutSession: session)
    container.mainContext.insert(set1)
    container.mainContext.insert(set2)
    
    return NavigationStack {
        ActiveWorkoutView(workoutSession: session)
    }
    .modelContainer(container)
}
