import SwiftUI
import SwiftData

struct SetEntrySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let exercise: Exercise
    let workoutSession: WorkoutSession
    
    @State private var weight: Double = 0
    @State private var reps: Int = 1
    @State private var sliderBase: Double = 0
    @State private var isDecimalMode: Bool = false
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    @FocusState private var isNameFocused: Bool
    
    @State private var editedName: String = ""
    
    private var weightStep: Double {
        isDecimalMode ? 0.5 : 1.0
    }
    
    private var sliderRange: ClosedRange<Double> {
        sliderBase...(sliderBase + 20)
    }
    
    // Determine smart defaults:
    private var smartDefaults: (weight: Double, reps: Int)? {
        workoutSession.smartDefaults(for: exercise)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Exercise")
                        Spacer()
                        TextField("Exercise Name", text: $editedName)
                            .focused($isNameFocused)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.primary)
                            .onSubmit {
                                saveExerciseName()
                            }
                    }
                }
                
                Section("Log Your Set") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Weight")
                            Spacer()
                            TextField("0", value: $weight, format: .number)
                                .focused($isWeightFocused)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                                    if let textField = obj.object as? UITextField {
                                        textField.selectAll(nil)
                                    }
                                }
                            Text("lbs")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $weight, in: sliderRange, step: weightStep)
                            .tint(.orange)
                            .onChange(of: weight) { oldValue, newValue in
                                if newValue.truncatingRemainder(dividingBy: 1.0) != 0 {
                                    isDecimalMode = true
                                }
                            }
                        
                        HStack {
                            Button {
                                sliderBase = max(0, sliderBase - 10)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                            
                            Spacer()
                            Text("\(Int(sliderRange.lowerBound)) — \(Int(sliderRange.upperBound))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            
                            Button {
                                sliderBase += 10
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Stepper(value: $reps, in: 1...100) {
                            HStack {
                                Text("Reps")
                                Spacer()
                                TextField("1", value: $reps, format: .number)
                                    .focused($isRepsFocused)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                    .frame(width: 60)
                                    .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
                                        if let textField = obj.object as? UITextField {
                                            textField.selectAll(nil)
                                        }
                                    }
                            }
                        }
                        
                        Slider(value: Binding(
                            get: { Double(reps) },
                            set: { reps = Int($0) }
                        ), in: 1...20, step: 1) {
                            Text("Reps")
                        } minimumValueLabel: {
                            Text("1")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } maximumValueLabel: {
                            Text("20")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if let pr = exercise.personalRecord {
                    Section("Personal Record") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Best")
                                Text(exercise.personalRecordDateDisplay)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            let weightString = pr.weight.formatted(.number.precision(.fractionLength(0...1)))
                            Text("\(weightString) lbs × \(pr.reps) reps")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    Button {
                        logSet()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Set")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(reps < 1)
                }
            }
            .navigationTitle("Log Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Initialize edited name
                editedName = exercise.name
                
                // Pre-fill with smart defaults (session history or PR)
                if let defaults = smartDefaults {
                    weight = defaults.weight
                    reps = defaults.reps
                    sliderBase = floor(weight / 10) * 10
                    isDecimalMode = weight.truncatingRemainder(dividingBy: 1.0) != 0
                }
            }
            .onDisappear {
                // Save name changes when sheet closes
                saveExerciseName()
            }
        }
    }
    
    private func logSet() {
        let newSet = ExerciseSet(
            weight: weight,
            reps: reps,
            exercise: exercise,
            workoutSession: workoutSession
        )
        modelContext.insert(newSet)
        dismiss()
    }
    
    private func saveExerciseName() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty && trimmedName != exercise.name {
            exercise.name = trimmedName
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, WorkoutSession.self, ExerciseSet.self, configurations: config)
    
    let exercise = Exercise(name: "Bench Press")
    let session = WorkoutSession()
    container.mainContext.insert(exercise)
    container.mainContext.insert(session)
    
    return SetEntrySheet(exercise: exercise, workoutSession: session)
        .modelContainer(container)
}
