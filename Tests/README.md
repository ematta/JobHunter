# JobHunter Tests

This directory contains the test suite for the JobHunter application. The tests are organized into unit tests and UI tests.

## Test Structure

- **Unit Tests**: Test individual components in isolation
  - `JobApplicationTests.swift`: Tests for the JobApplication model
  - `DatabaseManagerTests.swift`: Tests for the DatabaseManager class
- **UI Tests**: Test the user interface components
  - `UITests/MainViewControllerUITests.swift`: Tests for the main window interface

## Running Tests

### From Command Line

To run all tests:

```bash
cd JobHunter
swift test
```

To run a specific test:

```bash
cd JobHunter
swift test --filter JobApplicationTests
```

### From Xcode

1. Open the JobHunter project in Xcode
2. Select the test navigator in the navigator pane
3. Click the run button next to the test or test class you want to run

## Writing New Tests

### Adding a Unit Test

1. Create a new Swift file in the Tests directory
2. Import XCTest and the JobHunter module
3. Create a test class that inherits from XCTestCase
4. Add test methods that begin with "test"
5. Add the test class to the `allTests` array in LinuxMain.swift

Example:

```swift
import XCTest
@testable import JobHunter

final class NewFeatureTests: XCTestCase {
    func testFeatureBehavior() {
        // Test code here
        XCTAssertTrue(someCondition)
    }
    
    static var allTests = [
        ("testFeatureBehavior", testFeatureBehavior)
    ]
}
```

### Adding a UI Test

1. Create a new Swift file in the Tests/UITests directory
2. Import XCTest and the JobHunter module
3. Create a test class that inherits from XCTestCase
4. Add setUp and tearDown methods for UI initialization
5. Add test methods that begin with "test"
6. Add the test class to the `allTests` array in LinuxMain.swift

## Test Coverage

The test suite aims to cover:

1. **Models**: Ensure data structures work as expected
2. **Database Operations**: Verify CRUD operations work correctly
3. **UI Components**: Test user interactions and visual elements
4. **Application Logic**: Verify the business logic behaves as expected

## Mocking

For tests that require external dependencies (like the file system or iCloud), mock objects are used to isolate the component being tested. Mock implementations are in the `Mocks` directory.

## Continuous Integration

The tests are automatically run as part of the CI pipeline when changes are pushed to the repository. The pipeline configuration is in the `.github/workflows/tests.yml` file. 