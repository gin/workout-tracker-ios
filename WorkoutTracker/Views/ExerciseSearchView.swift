import SwiftUI
import SwiftData

struct ExerciseSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    
    @State private var searchText = ""
    
    let workoutSession: WorkoutSession
    let onExerciseSelected: (Exercise) -> Void
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var showCreateOption: Bool {
        !searchText.isEmpty && !exercises.contains { $0.name.localizedCaseInsensitiveCompare(searchText) == .orderedSame }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if showCreateOption {
                    Section {
                        Button {
                            createAndSelectExercise()
                        } label: {
                            Label("Create \"\(searchText)\"", systemImage: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                Section(filteredExercises.isEmpty ? "" : "Exercises") {
                    ForEach(filteredExercises) { exercise in
                        Button {
                            onExerciseSelected(exercise)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(exercise.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("Best: \(exercise.personalRecordDisplay)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createAndSelectExercise() {
        let exercise = Exercise(name: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(exercise)
        onExerciseSelected(exercise)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, WorkoutSession.self, ExerciseSet.self, configurations: config)
    
    let session = WorkoutSession()
    container.mainContext.insert(session)
    
    // Add some sample exercises
    let benchPress = Exercise(name: "Bench Press")
    let squat = Exercise(name: "Squat")
    container.mainContext.insert(benchPress)
    container.mainContext.insert(squat)
    
    return ExerciseSearchView(workoutSession: session) { _ in }
        .modelContainer(container)
}
