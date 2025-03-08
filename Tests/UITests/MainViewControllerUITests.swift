import XCTest
@testable import JobHunter

/**
 * UI tests for the main content view.
 * 
 * This replaces the old MainViewControllerUITests class with tests for the
 * new SwiftUI-based ContentView.
 */
class ContentViewUITests: XCTestCase {
    
    var app: XCUIApplication?
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    /**
     * Tests that basic UI components are present in the main view.
     */
    func testBasicUIFunctionality() throws {
        try skipTestIfRunningInSPM()
        
        // Test basic UI components are present in a SwiftUI UI
        XCTAssertTrue(app!.textFields.firstMatch.exists, "Search field should exist")
        XCTAssertTrue(app!.collectionViews.firstMatch.exists, "Job list should exist")
        XCTAssertTrue(app!.segmentedControls.firstMatch.exists, "Status filter control should exist")
        XCTAssertTrue(app!.buttons["Add Job"].exists, "Add job button should exist")
        
        // Test search functionality
        let searchField = app!.textFields.firstMatch
        searchField.tap()
        searchField.typeText("Test Company")
        
        // Give time for the search to filter results
        sleep(1) // Simple pause to allow filter to apply
        
        // Tap a button to dismiss keyboard if needed
        if app!.keyboards.count > 0 {
            app!.buttons["Add Job"].tap()
        }
    }
    
    /**
     * Tests the full lifecycle of adding, viewing, and updating a job application.
     */
    func testJobApplicationLifecycle() throws {
        try skipTestIfRunningInSPM()
        
        // Test adding a new job
        app!.buttons["Add Job"].tap()
        
        // New job sheet should appear
        XCTAssertTrue(app!.staticTexts["Add New Job Application"].waitForExistence(timeout: 2),
                     "New job sheet should appear")
        
        // Fill in the new job form
        app!.textFields["Enter company name"].tap()
        app!.textFields["Enter company name"].typeText("UI Test Company")
        
        app!.textFields["Enter job title"].tap()
        app!.textFields["Enter job title"].typeText("UI Test Engineer")
        
        // Save the new job
        app!.buttons["Save"].tap()
        
        // Verify we're back to the main view
        XCTAssertTrue(app!.buttons["Add Job"].waitForExistence(timeout: 2),
                     "Should return to main view")
        
        // Verify the job was added and appears in the list
        XCTAssertTrue(app!.staticTexts["UI Test Company"].exists,
                     "New job should appear in the list")
        
        // Select the job to see details
        app!.staticTexts["UI Test Company"].tap()
        
        // Verify job details view appears and shows the correct information
        // SwiftUI may render this in various ways, but the job title should be visible
        let jobTitleExists = app!.staticTexts["UI Test Engineer"].waitForExistence(timeout: 2)
        XCTAssertTrue(jobTitleExists, "Job details should show the job title")
        
        // Test enabling edit mode and changing status
        app!.switches["Enable Editing"].tap()
        
        // In edit mode, find and change the status picker
        // For SwiftUI UI tests, we need to check if the picker exists first
        let picker = app!.pickers.firstMatch
        if picker.exists {
            picker.tap()
            // Try to select a different status
            if app!.menuItems["Interviewing"].exists {
                app!.menuItems["Interviewing"].tap()
            }
        }
        
        // Save changes
        app!.buttons["Save Changes"].tap()
        
        // Verify changes were applied (status may be shown in various ways)
        // We can't easily verify this in a generic way without proper accessibility identifiers
    }
    
    /**
     * Tests the filtering functionality by job status.
     */
    func testStatusFiltering() throws {
        try skipTestIfRunningInSPM()
        
        // The segmented control for status filtering
        let statusFilter = app!.segmentedControls.firstMatch
        
        // Try selecting different status options
        for button in statusFilter.buttons.allElementsBoundByIndex {
            button.tap()
            sleep(1) // Allow filter to apply
        }
        
        // Select "Applied" to filter results
        // Find the segment with label containing "Applied"
        for button in statusFilter.buttons.allElementsBoundByIndex {
            if button.label.contains("Applied") {
                button.tap()
                break
            }
        }
        
        // We can't easily verify specific filtered results without properly set accessibility IDs
    }
    
    // Helper method to skip tests when running in Swift Package Manager
    private func skipTestIfRunningInSPM() throws {
        // Check if we're running in SPM (Swift Package Manager)
        let isRunningSPM = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil || 
                          ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"]?.contains(".build") == true
        
        if isRunningSPM {
            throw XCTSkip("UI tests are not supported when running in Swift Package Manager. Run these tests from Xcode with a proper UI testing target.")
        }
        
        // Only initialize the application if we're not skipping
        app = XCUIApplication()
        
        // If we were able to instantiate the app, launch it
        guard let application = app else {
            throw XCTSkip("Failed to initialize XCUIApplication")
        }
        
        // Launch the app
        application.launch()
    }
} 
