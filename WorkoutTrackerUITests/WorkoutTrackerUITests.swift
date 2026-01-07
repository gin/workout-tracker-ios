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
        let firstExercise = app.buttons.matching(identifier: "Bicep curl").firstMatch
        
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
