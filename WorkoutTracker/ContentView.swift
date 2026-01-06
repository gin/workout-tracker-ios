import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WorkoutSession> { $0.isActive == true }) 
    private var activeWorkouts: [WorkoutSession]
    
    @Query(filter: #Predicate<WorkoutSession> { $0.isActive == false }, sort: \WorkoutSession.date, order: .reverse)
    private var pastWorkouts: [WorkoutSession]
    
    @State private var showSummary: WorkoutSession?
    @State private var editingWorkout: WorkoutSession?
    @State private var keepScreenOn = false
    
    var activeWorkout: WorkoutSession? {
        activeWorkouts.first
    }
    
    var body: some View {
        NavigationStack {
            homeView
        }
        .sheet(item: $showSummary) { workout in
            WorkoutSummaryView(workoutSession: workout)
        }
        .sheet(item: $editingWorkout) { workout in
            NavigationStack {
                ActiveWorkoutView(workoutSession: workout)
            }
            .interactiveDismissDisabled(false)
        }
        .onAppear {
            // Auto-open if there's an active workout
            if let workout = activeWorkout {
                editingWorkout = workout
            }
        }
        .onChange(of: activeWorkout) { oldValue, newValue in
            // When a new workout starts (newValue is not nil, oldValue was nil)
            if let newValue, oldValue == nil {
                editingWorkout = newValue
            }
            
            // When a workout finishes (newValue is nil, oldValue was not nil)
            if newValue == nil, let finishedWorkout = oldValue {
                editingWorkout = nil
                
                // Only show summary if the workout wasn't canceled (deleted)
                // We check if it has sets to determine if it's worth showing a summary
                if !finishedWorkout.sets.isEmpty {
                    // Small delay to ensure the first sheet dismisses before showing the next one
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showSummary = finishedWorkout
                    }
                }
            }
        }
    }
    
    private var homeView: some View {
        List {
            // Active workout section
            if activeWorkout != nil {
                Section {
                    Button {
                        editingWorkout = activeWorkout
                    } label: {
                        Label("Resume Workout", systemImage: "figure.run")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal)
                }
            } else {
                Section {
                    Button {
                        startNewWorkout()
                    } label: {
                        Label {
                            Text("Start New Workout")
                        } icon: {
                            Image(systemName: "play")
                                .foregroundStyle(.green)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal)
                }
            }
            
            if !pastWorkouts.isEmpty {
                Section("History") {
                    ForEach(pastWorkouts) { workout in
                        Button {
                            showSummary = workout
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(workout.date, format: .dateTime.weekday().month().day())
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(workout.exercises.count) exercises • \(workout.sets.count) sets")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteWorkouts)
                }
            }
        }
        .navigationTitle("Workout Tracker")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    keepScreenOn.toggle()
                    UIApplication.shared.isIdleTimerDisabled = keepScreenOn
                } label: {
                    Image(systemName: keepScreenOn ? "sun.max.fill" : "sun.max")
                        .foregroundStyle(keepScreenOn ? .yellow : .secondary)
                }
                .accessibilityLabel(keepScreenOn ? "Screen always on" : "Screen can turn off")
            }
            
            if !pastWorkouts.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func startNewWorkout() {
        withAnimation {
            let newWorkout = WorkoutSession()
            modelContext.insert(newWorkout)
        }
    }
    
    private func deleteWorkouts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(pastWorkouts[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, WorkoutSession.self, ExerciseSet.self], inMemory: true)
}
