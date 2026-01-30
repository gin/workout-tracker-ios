import XCTest

final class WorkoutTrackerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        // In UI tests it is usually best to stop immediately when a failure occurs.
    }

    @MainActor
    func testFullWorkoutFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        // 1. Start Workout
        let startButton = app.buttons["Start New Workout"]
//        let resumeButton = app.buttons["Resume Workout"]
        // Ensure we are in a workout or start one
        if startButton.waitForExistence(timeout: 2) {
            startButton.tap()
        }
//        } else if resumeButton.exists {
//            resumeButton.tap()
//        }
        
        // 2. Add Exercise
        let plusButton = app.buttons["plus"]
        XCTAssertTrue(plusButton.waitForExistence(timeout: 2), "Plus button should exist")
        plusButton.tap()
        
        // Search sheet should appear.
        // TODO: if does not exist, create it.
        let firstExercise: XCUIElement = {
            let buttons = app.buttons.allElementsBoundByIndex
            if let match = buttons.first(where: { element in
                let label = element.label
                let identifier = element.identifier
                return label.lowercased().hasPrefix("bicep curl") || identifier.lowercased().hasPrefix("bicep curl")
            }) {
                return match
            } else {
                return app.buttons["Bicep curl"]
            }
        }()
        
        if firstExercise.waitForExistence(timeout: 20) {
            firstExercise.tap()
        } else {
            app.buttons["Cancel"].tap()
        }
        
        // 3. Log Set (SetEntrySheet)
        // Wait for sheet to appear
        let logSetButton = app.buttons["Log Set"]
        if logSetButton.waitForExistence(timeout: 2) {
            logSetButton.tap()
        }
        
        // 4. Finish Workout
        let finishButton = app.buttons["Finish Workout"]
        XCTAssertTrue(finishButton.waitForExistence(timeout: 2))
        finishButton.tap()
        
        // 5. Slide to Finish
        let slider = app.staticTexts["Slide to Finish"]
        XCTAssertTrue(slider.waitForExistence(timeout: 1))
        
        // Perform swipe using explicit handle
        let sliderHandle = app.otherElements["SlideHandle"]
        XCTAssertTrue(sliderHandle.waitForExistence(timeout: 2))
        sliderHandle.longSwipe(.right)
        
        // 6. Verify Summary
        let summaryTitle = app.staticTexts["Workout Summary"]
        XCTAssertTrue(summaryTitle.waitForExistence(timeout: 2))
        
        app.buttons["Done"].tap()
        
        let historyHeader = app.staticTexts["History"]
        XCTAssertTrue(historyHeader.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testCancelWorkout() throws {
        let app = XCUIApplication()
        app.launch()
        
        let startButton = app.buttons["Start New Workout"]
        let resumeButton = app.buttons["Resume Workout"]
        // Ensure we are in a workout or start one
        if startButton.waitForExistence(timeout: 2) {
            startButton.tap()
        } else if resumeButton.exists {
            resumeButton.tap()
        }
        
        // Tap Finish
        let finishButton = app.buttons["Cancel Workout"]
        XCTAssertTrue(finishButton.waitForExistence(timeout: 20))
        finishButton.tap()

        // Verify we are back to the start screen
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testKeepScreenOnButton() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Find the Keep Screen On button
        let keepScreenOnButton = app.buttons["keepScreenOnButton"]
        XCTAssertTrue(keepScreenOnButton.waitForExistence(timeout: 2), "Keep Screen On button should exist")
        
        // TODO: Add a step to ensure which state the button is. Reset to Off before continuing.
        // Verify initial state - screen can turn off
        XCTAssertEqual(keepScreenOnButton.label, "Screen can turn off", "Initial state should be 'Screen can turn off'")
        
        // Tap to turn on
        keepScreenOnButton.tap()
        
        // Verify state changed - screen always on
        XCTAssertEqual(keepScreenOnButton.label, "Screen always on", "After tap, state should be 'Screen always on'")
        
        // Tap again to turn off
        keepScreenOnButton.tap()
        
        // Verify state reverted - screen can turn off
        XCTAssertEqual(keepScreenOnButton.label, "Screen can turn off", "After second tap, state should revert to 'Screen can turn off'")
    }
    
    @MainActor
    func testReuseWorkoutCancelThenNewWorkout_NameIsEmpty() throws {
        let app = XCUIApplication()
        app.launch()
        
        // First, we need a past workout to exist
        // Complete a workout first if there's no history
        let historyHeader = app.staticTexts["History"]
        if !historyHeader.waitForExistence(timeout: 2) {
            // Create a workout first
            try createAndFinishWorkout(app: app)
        }
        
        // 1. Tap on a past workout to open summary
        let historyCell = app.buttons.matching(NSPredicate(format: "label CONTAINS 'exercises'")).firstMatch
        XCTAssertTrue(historyCell.waitForExistence(timeout: 2), "Should have a past workout")
        historyCell.tap()
        
        // 2. Tap "Reuse Workout"
        let reuseButton = app.buttons["Reuse Workout"]
        XCTAssertTrue(reuseButton.waitForExistence(timeout: 2), "Reuse Workout button should exist")
        reuseButton.tap()
        
        // 3. Cancel the workout
        let cancelButton = app.buttons["Cancel Workout"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2), "Cancel Workout button should exist")
        cancelButton.tap()
        
        // 4. Start new workout
        let startButton = app.buttons["Start New Workout"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2), "Start New Workout button should exist")
        startButton.tap()
        
        // 5. Add an exercise
        let plusButton = app.buttons["plus"]
        XCTAssertTrue(plusButton.waitForExistence(timeout: 2), "Plus button should exist")
        plusButton.tap()
        
        let firstExercise: XCUIElement = {
            let buttons = app.buttons.allElementsBoundByIndex
            if let match = buttons.first(where: { element in
                let label = element.label
                let identifier = element.identifier
                return label.lowercased().hasPrefix("bicep curl") || identifier.lowercased().hasPrefix("bicep curl")
            }) {
                return match
            } else {
                return app.buttons["Bicep curl"]
            }
        }()
        
        if firstExercise.waitForExistence(timeout: 5) {
            firstExercise.tap()
        } else {
            app.buttons["Cancel"].tap()
            return // Skip if no exercises exist
        }
        
        // 6. Log a set
        let logSetButton = app.buttons["Log Set"]
        if logSetButton.waitForExistence(timeout: 2) {
            logSetButton.tap()
        }
        
        // 7. Finish the workout
        let finishButton = app.buttons["Finish Workout"]
        XCTAssertTrue(finishButton.waitForExistence(timeout: 2))
        finishButton.tap()
        
        // Slide to finish
        let sliderHandle = app.otherElements["SlideHandle"]
        XCTAssertTrue(sliderHandle.waitForExistence(timeout: 2))
        sliderHandle.longSwipe(.right)
        
        // 8. Verify workout summary shows - name field should be empty
        let summaryTitle = app.staticTexts["Workout Summary"]
        XCTAssertTrue(summaryTitle.waitForExistence(timeout: 2))
        
        // Check that the Name text field placeholder is "Workout Name" (meaning it's empty)
        let nameField = app.textFields["Workout Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should exist")
        
        // The text field should be empty (only placeholder visible)
        let nameValue = nameField.value as? String ?? ""
        XCTAssertTrue(nameValue.isEmpty || nameValue == "Workout Name", "Name should be empty for a fresh workout, got: \(nameValue)")
    }
    
    private func createAndFinishWorkout(app: XCUIApplication) throws {
        let startButton = app.buttons["Start New Workout"]
        if startButton.waitForExistence(timeout: 2) {
            startButton.tap()
        }
        
        let plusButton = app.buttons["plus"]
        if plusButton.waitForExistence(timeout: 2) {
            plusButton.tap()
        }
        
        let firstExercise: XCUIElement = {
            let buttons = app.buttons.allElementsBoundByIndex
            if let match = buttons.first(where: { element in
                let label = element.label
                let identifier = element.identifier
                return label.lowercased().hasPrefix("bicep curl") || identifier.lowercased().hasPrefix("bicep curl")
            }) {
                return match
            } else {
                return app.buttons["Bicep curl"]
            }
        }()
        
        if firstExercise.waitForExistence(timeout: 5) {
            firstExercise.tap()
        } else {
            app.buttons["Cancel"].tap()
            return
        }
        
        let logSetButton = app.buttons["Log Set"]
        if logSetButton.waitForExistence(timeout: 2) {
            logSetButton.tap()
        }
        
        let finishButton = app.buttons["Finish Workout"]
        if finishButton.waitForExistence(timeout: 2) {
            finishButton.tap()
        }
        
        let sliderHandle = app.otherElements["SlideHandle"]
        if sliderHandle.waitForExistence(timeout: 2) {
            sliderHandle.longSwipe(.right)
        }
        
        // Dismiss summary
        let doneButton = app.buttons["Done"]
        if doneButton.waitForExistence(timeout: 2) {
            doneButton.tap()
        }
    }
}

extension XCUIElement
{
    enum SwipeDirection {
        case left, right
    }
    
    func longSwipe(_ direction : SwipeDirection) {
        let startOffset: CGVector
        let endOffset: CGVector
        
        switch direction {
        case .right:
            startOffset = CGVector(dx: 0.1, dy: 0.5)
            endOffset = CGVector(dx: 0.9, dy: 0.5)
        case .left:
            startOffset = CGVector(dx: 0.9, dy: 0.5)
            endOffset = CGVector(dx: 0.1, dy: 0.5)
        }
        
        let startPoint = coordinate(withNormalizedOffset: startOffset)
        let endPoint = coordinate(withNormalizedOffset: endOffset)
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
    }
}

