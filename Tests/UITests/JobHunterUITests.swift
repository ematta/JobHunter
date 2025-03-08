import XCTest
@testable import JobHunter

final class JobHunterUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        #if !RUNNING_IN_SPM
        app = XCUIApplication()
        app.launch()
        #else
        throw XCTSkip("UI tests must be run from Xcode")
        #endif
    }
    
    override func tearDownWithError() throws {
        #if !RUNNING_IN_SPM
        app.terminate()
        app = nil
        #endif
    }
    
    func testMainWindowElements() throws {
        #if RUNNING_IN_SPM
        throw XCTSkip("UI tests must be run from Xcode")
        #else
        // Verify main window elements are present
        XCTAssertTrue(app.windows["JobHunter"].exists)
        
        // SwiftUI List instead of NSTableView
        XCTAssertTrue(app.collectionViews.firstMatch.exists, "Job list should exist")
        
        // SwiftUI TextField for search
        XCTAssertTrue(app.textFields.firstMatch.exists, "Search field should exist")
        
        // SwiftUI Picker for status filtering (appears as SegmentedControl)
        XCTAssertTrue(app.segmentedControls.firstMatch.exists, "Status filter should exist")
        
        // Button to add new job
        XCTAssertTrue(app.buttons["Add Job"].exists, "Add Job button should exist")
        #endif
    }
    
    func testAddNewJob() throws {
        #if RUNNING_IN_SPM
        throw XCTSkip("UI tests must be run from Xcode")
        #else
        // Click add new job button
        app.buttons["Add Job"].tap()
        
        // Verify new job sheet appears (SwiftUI sheets appear differently)
        XCTAssertTrue(app.staticTexts["Add New Job Application"].waitForExistence(timeout: 2), 
                      "New job form should appear")
        
        // Fill in job details - identifiers are different in SwiftUI
        // For text fields we can use placeholders to identify them
        app.textFields["Enter company name"].tap()
        app.textFields["Enter company name"].typeText("Test Company")
        
        app.textFields["Enter job title"].tap()
        app.textFields["Enter job title"].typeText("Test Position")
        
        // SwiftUI DatePickers don't typically respond to typing
        // Just verify they exist
        XCTAssertTrue(app.datePickers.count > 0, "Date pickers should exist")
        
        // Save job - use the button label
        app.buttons["Save"].tap()
        
        // Verify we're back to the main view and job appears in list
        XCTAssertTrue(app.buttons["Add Job"].waitForExistence(timeout: 2), 
                     "Should return to main view")
        
        // Check for job in list - SwiftUI List will have Text elements
        XCTAssertTrue(app.staticTexts["Test Company"].exists || 
                     app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Test Company'")).firstMatch.exists, 
                     "Added job should appear in the list")
        #endif
    }
    
    func testJobFiltering() throws {
        #if RUNNING_IN_SPM
        throw XCTSkip("UI tests must be run from Xcode")
        #else
        // Ensure we have at least one job
        if !app.staticTexts["Test Company"].exists {
            try testAddNewJob()
        }
        
        // Test search filtering
        let searchField = app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("Test")
        
        // Verify filtered results
        let timeout = 2.0
        let predicate = NSPredicate(format: "exists == 1")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, 
                                                  object: app.staticTexts["Test Company"])
        _ = XCTWaiter.wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(app.staticTexts["Test Company"].exists, 
                     "Job should be visible after filtering")
        
        // Clear search field
        searchField.tap()
        searchField.buttons["Clear text"].tap()
        
        // Test status filtering using the segmented control
        let statusFilter = app.segmentedControls.firstMatch
        
        // Select the "Applied" segment (index may vary)
        // Find the segment with label containing "Applied"
        for button in statusFilter.buttons.allElementsBoundByIndex {
            if button.label.contains("Applied") {
                button.tap()
                break
            }
        }
        
        // Verify the filtered results
        XCTAssertTrue(app.staticTexts["Test Company"].exists || 
                     app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Test Company'")).firstMatch.exists, 
                     "Job should be visible after status filtering")
        #endif
    }
} 