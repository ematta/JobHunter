import XCTest
@testable import JobHunter

class MainViewControllerUITests: XCTestCase {
    
    var app: XCUIApplication?
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    func testBasicUIFunctionality() throws {
        try skipTestIfRunningInSPM()
        
        // Test basic UI components are present
        XCTAssertTrue(app!.searchFields.element.exists, "Search field should exist")
        XCTAssertTrue(app!.tables["jobsTableView"].exists, "Jobs table view should exist")
        XCTAssertTrue(app!.segmentedControls["statusSegmentedControl"].exists, "Status filter control should exist")
        XCTAssertTrue(app!.buttons["addJobButton"].exists, "Add job button should exist")
        
        // Test search functionality
        let searchField = app!.searchFields.element
        searchField.tap()
        searchField.typeText("Test Company")
        
        // Give time for the search to filter results
        let predicate = NSPredicate(format: "count > 0")
        let tableViewCell = app!.tables["jobsTableView"].cells.element
        expectation(for: predicate, evaluatedWith: tableViewCell, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testJobApplicationLifecycle() throws {
        try skipTestIfRunningInSPM()
        
        // Test adding a new job
        app!.buttons["addJobButton"].tap()
        
        // New job form should appear
        XCTAssertTrue(app!.windows["newJobWindow"].exists, "New job window should appear")
        
        // Fill in the new job form
        let companyField = app!.textFields["companyTextField"]
        companyField.tap()
        companyField.typeText("Test Company")
        
        let positionField = app!.textFields["positionTextField"]
        positionField.tap() 
        positionField.typeText("Software Engineer")
        
        // Save the new job
        app!.buttons["saveJobButton"].tap()
        
        // Verify the job was added to the table
        let jobsTable = app!.tables["jobsTableView"]
        XCTAssertTrue(jobsTable.cells.count > 0, "Job should be added to the table")
        
        // Select the job and verify details appear
        jobsTable.cells.element(boundBy: 0).tap()
        
        // Verify job details are displayed
        XCTAssertTrue(app!.staticTexts["Test Company"].exists, "Company name should be displayed in details")
        XCTAssertTrue(app!.staticTexts["Software Engineer"].exists, "Position should be displayed in details")
        
        // Test changing job status
        app!.popUpButtons["statusPopUp"].tap()
        app!.menuItems["Interview"].tap()
        
        // Verify status is updated
        XCTAssertTrue(app!.staticTexts["Interview"].exists, "Status should be updated to Interview")
    }
    
    // Helper method to skip tests when running in Swift Package Manager
    private func skipTestIfRunningInSPM() throws {
        // Check if we're running in SPM (Swift Package Manager)
        // When running in SPM, we typically don't have a proper UI test target setup
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
    
    func testStatusFiltering() throws {
        try skipTestIfRunningInSPM()
        
        // Test status filtering
        let statusFilter = app!.segmentedControls["statusFilter"]
        statusFilter.buttons["Applied"].tap()
        
        // Verify filtered results
        let jobsTable = app!.tables["jobsTableView"]
        XCTAssertTrue(jobsTable.cells.count > 0)
    }
} 
