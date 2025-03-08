# JobHunter Developer Documentation

## Architecture Overview

JobHunter follows the Model-View-Controller (MVC) architecture pattern:

- **Models**: Represent the data and business logic of the application
- **Views**: Handle the UI components and user interactions
- **Controllers**: Connect the models and views, handling the application logic

## Project Structure

- **Sources/**: Contains all Swift source files
  - **Models/**: Data models and database interactions
    - `JobApplication.swift`: Defines the JobApplication struct
    - `Attachment.swift`: Defines the Attachment struct
    - `DatabaseManager.swift`: Handles SQLite database operations
  - **Views/**: User interface components
    - `JobDetailView.swift`: Displays detailed information about a job application
    - (Other view files)
  - **Controllers/**: Business logic
    - `AppController.swift`: Main application controller
    - `MainViewController.swift`: Controls the main window
    - `NewJobViewController.swift`: Controls the new/edit job form
  - **Utilities/**: Helper functions and extensions
    - (Utility files)
  - `main.swift`: Entry point of the application
- **Resources/**: Images, icons, and other assets
- **Tests/**: Unit and UI tests

## Database Schema

JobHunter uses SQLite with the following schema:

### Jobs Table

| Column Name | Type | Description |
|-------------|------|-------------|
| JobID | INTEGER | Primary key, auto-incremented |
| CompanyName | TEXT | Name of the company |
| JobTitle | TEXT | Title of the job position |
| ApplicationDate | DATE | Date when the application was submitted |
| ApplicationDeadline | DATE | Deadline for the application |
| ApplicationStatus | TEXT | Current status of the application |
| JobDescription | TEXT | Description or URL of the job posting |
| Notes | TEXT | User notes about the application |
| ContactName | TEXT | Name of the contact person |
| ContactEmail | TEXT | Email of the contact person |
| ContactPhone | TEXT | Phone number of the contact person |

### Attachments Table

| Column Name | Type | Description |
|-------------|------|-------------|
| AttachmentID | INTEGER | Primary key, auto-incremented |
| JobID | INTEGER | Foreign key referencing Jobs.JobID |
| FilePath | TEXT | Path to the attached document |

## Key Components

### DatabaseManager

The `DatabaseManager` class handles all database operations including:
- Creating and upgrading the database
- CRUD operations for job applications and attachments
- Data migration and sync with iCloud

### AppController

The `AppController` class serves as the main controller for the application, responsible for:
- Initializing and managing the database
- Coordinating between different view controllers
- Handling application lifecycle events

### MainViewController

The `MainViewController` controls the main window and is responsible for:
- Displaying the list of job applications
- Managing filtering and searching
- Handling selection and navigation

### NewJobViewController

The `NewJobViewController` is responsible for:
- Creating new job applications
- Editing existing job applications
- Validating user input

## iCloud Integration

JobHunter uses CloudKit and iCloud document storage for:
- Syncing the SQLite database across devices
- Storing and syncing attached documents

The iCloud integration is managed through:
- `NSUbiquitousKeyValueStore` for small key-value data
- `NSFileCoordinator` and `NSFilePresenter` for file coordination
- `NSMetadataQuery` for discovering changes in iCloud containers

## PDF Document Handling

PDF documents are handled using:
- `PDFKit` for viewing and basic PDF operations
- `NSFileManager` for file operations

## Adding New Features

### Adding a New Model

1. Create a new Swift file in the `Models` directory
2. Define your model struct or class
3. Add necessary properties and methods
4. Update the `DatabaseManager` class to handle CRUD operations for the new model

### Adding a New View

1. Create a new Swift file in the `Views` directory
2. Define your view class, inheriting from `NSView` or a subclass
3. Implement the user interface elements
4. Connect to controllers as needed

### Adding a New Controller

1. Create a new Swift file in the `Controllers` directory
2. Define your controller class, inheriting from `NSViewController` or a subclass
3. Implement the necessary methods to connect models and views
4. Register with the `AppController` if needed

## Testing

### Unit Tests

Unit tests are located in the `Tests` directory and focus on testing individual components in isolation. Key test areas include:
- Model validation and business logic
- Database operations
- Controller logic

### UI Tests

UI tests simulate user interactions to test the application's interface. These tests focus on:
- User workflows (adding/editing/deleting job applications)
- UI responsiveness
- Integration between components

## Build and Release Process

### Development Build

1. Clone the repository
2. Run `swift package resolve` to install dependencies
3. Run `swift build` to build the project
4. Run `swift run JobHunter` to run the application

### Production Build

1. Update version information in `Info.plist`
2. Run the build script: `./build.sh`
3. Sign the application with your Developer ID
4. Create a DMG file for distribution
5. Submit to the Mac App Store or distribute via your website

## Troubleshooting Common Development Issues

### Database Issues

- Check file permissions for SQLite database file
- Use SQLite CLI or DB Browser for SQLite to inspect database directly
- Enable debug logging in the `DatabaseManager`

### UI Issues

- Use Interface Inspector in Xcode to debug layout issues
- Add debug code to log view hierarchy
- Test with different screen sizes and resolutions

### iCloud Issues

- Test with a dedicated Apple ID for development
- Check entitlements and capabilities in Xcode project
- Use CloudKit Dashboard to inspect cloud data 