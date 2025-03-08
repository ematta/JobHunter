# JobHunter Testing Guide

This guide provides detailed instructions for running and writing tests for the JobHunter application.

## Testing Prerequisites

Before running tests, ensure you have:

1. Xcode 13.4 or later installed
2. Swift 5.7 or later
3. All required dependencies installed

## Test Categories

JobHunter tests are divided into several categories:

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test how components work together
3. **UI Tests**: Test user interface components
4. **Performance Tests**: Test application performance under various conditions

## Running Tests

### From Command Line

To run all tests:

```bash
cd JobHunter
swift test
```

To run a specific test category:

```bash
cd JobHunter
swift test --filter "JobApplicationTests"
```

To run a specific test method:

```bash
cd JobHunter
swift test --filter "JobApplicationTests/testJobApplicationInitialization"
```

### From Xcode

1. Open the JobHunter project in Xcode
2. Select the test navigator in the navigator pane (⌘6)
3. Click the run button (▶) next to the test or test class you want to run
4. To run all tests, use ⌘U

## Test Structure

### Unit Tests

Unit tests focus on testing individual components in isolation. Each model, service, and utility has its own test class:

- `JobApplicationTests.swift`: Tests the JobApplication model
- `DatabaseManagerTests.swift`: Tests database operations
- `AttachmentTests.swift`: Tests the Attachment model

Example unit test:

```swift
func testJobApplicationInitialization() {
    let date = Date()
    let job = JobApplication(
        id: 1,
        companyName: "Test Company",
        // ... other properties
    )
    
    XCTAssertEqual(job.id, 1)
    XCTAssertEqual(job.companyName, "Test Company")
    // ... other assertions
}
```

### UI Tests

UI tests verify that the interface works correctly:

- `MainViewControllerUITests.swift`: Tests the main window and its components
- `NewJobViewControllerUITests.swift`: Tests the new job form
- `JobDetailViewUITests.swift`: Tests the job detail view

Example UI test:

```swift
func testSearchJob() {
    // Set search text
    mainViewController.searchField.stringValue = "Test Company"
    mainViewController.searchFieldDidChange(nil)
    
    // Ensure the correct job is found
    let jobsCount = mainViewController.jobsTableView.numberOfRows
    XCTAssertEqual(jobsCount, 1, "Should have 1 job in the search results")
}
```

## Writing Effective Tests

### Test Guidelines

1. **Test One Thing**: Each test should focus on testing one specific functionality
2. **Independent Tests**: Tests should not depend on each other
3. **Descriptive Names**: Use descriptive test names that indicate what is being tested
4. **Arrange-Act-Assert**: Structure tests with setup, action, and verification phases
5. **Mock Dependencies**: Use mock objects for external dependencies

### Example: Testing with Mocks

```swift
func testDatabaseOperations() {
    // Setup - use mock database manager
    let mockDB = MockDatabaseManager()
    
    // Act - perform operations
    let jobId = mockDB.addJob(/* parameters */)
    
    // Assert - verify results
    XCTAssertNotNil(mockDB.getJob(id: jobId))
}
```

## Test Coverage

JobHunter aims for at least 80% test coverage. Key areas that should be tested include:

1. **Core Models**: All model properties and methods
2. **Database Operations**: All CRUD operations
3. **User Interface**: All user interactions
4. **Business Logic**: All application logic

## Continuous Integration

Tests are automatically run on GitHub Actions when changes are pushed to the repository. The CI pipeline:

1. Builds the project
2. Runs all tests
3. Generates a test coverage report
4. Reports build and test status on pull requests

## Debugging Tests

If a test fails:

1. Read the test failure message for details
2. Set breakpoints in the test to step through execution
3. Use `print` statements to debug values
4. Check test assumptions and expected values

## Performance Testing

Performance tests ensure the application remains responsive with large datasets:

```swift
func testDatabasePerformance() {
    measure {
        // Code to measure
        for i in 1...100 {
            _ = dbManager.addJob(/* parameters */)
        }
    }
}
```

## Regression Testing

When fixing bugs:

1. First write a test that reproduces the bug
2. Fix the bug
3. Verify the test passes
4. Include both the fix and the test in the same pull request

This ensures the bug doesn't reappear in the future. 