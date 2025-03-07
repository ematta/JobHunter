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
        XCTAssertTrue(app.tables["jobsTableView"].exists)
        XCTAssertTrue(app.searchFields["searchField"].exists)
        XCTAssertTrue(app.segmentedControls["statusFilter"].exists)
        #endif
    }
    
    func testAddNewJob() throws {
        #if RUNNING_IN_SPM
        throw XCTSkip("UI tests must be run from Xcode")
        #else
        // Click add new job button
        app.buttons["addJobButton"].click()
        
        // Verify new job window appears
        let newJobWindow = app.windows["New Job"]
        XCTAssertTrue(newJobWindow.exists)
        
        // Fill in job details
        newJobWindow.textFields["companyName"].typeText("Test Company")
        newJobWindow.textFields["jobTitle"].typeText("Test Position")
        newJobWindow.textFields["applicationDate"].typeText("2024-03-07")
        newJobWindow.textFields["applicationDeadline"].typeText("2024-04-07")
        
        // Save job
        newJobWindow.buttons["saveButton"].click()
        
        // Verify job appears in table
        let jobsTable = app.tables["jobsTableView"]
        XCTAssertTrue(jobsTable.cells.containing(NSPredicate(format: "label CONTAINS 'Test Company'")).element.exists)
        #endif
    }
    
    func testJobFiltering() throws {
        #if RUNNING_IN_SPM
        throw XCTSkip("UI tests must be run from Xcode")
        #else
        // Add test data if needed
        
        // Test search filtering
        let searchField = app.searchFields["searchField"]
        searchField.click()
        searchField.typeText("Test")
        
        // Verify filtered results
        let jobsTable = app.tables["jobsTableView"]
        XCTAssertTrue(jobsTable.cells.count > 0)
        
        // Test status filtering
        let statusFilter = app.segmentedControls["statusFilter"]
        statusFilter.buttons["Applied"].click()
        
        // Verify filtered results
        XCTAssertTrue(jobsTable.cells.count > 0)
        #endif
    }
} 