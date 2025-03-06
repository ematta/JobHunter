# JobHunter

A macOS application for tracking and managing job applications, built with Swift and SQLite.

## Features

- Track job applications (company, position, status, deadlines, etc.)
- Store and view related documents (resumes, cover letters)
- iCloud integration for data storage and sync
- SQLite database for efficient data management
- Visual status tracking with color-coded indicators
- Search and filter functionality

## Requirements

- macOS 12 Monterey or later
- Xcode 13.4 or later (for building)
- VS Code with Swift extensions (for development)

## Development Setup

1. Clone this repository
2. Open the folder in VS Code
3. Install the "Swift" extension for VS Code
4. Install the required dependencies:
   ```
   cd JobHunter
   swift package resolve
   ```

5. Enable iCloud capabilities in your Apple Developer account and update the `entitlements.plist` file accordingly

## Building

To build the project:

```bash
cd JobHunter
swift build
```

To run the project:

```bash
swift run JobHunter
```

## Project Structure

- `Sources/` - Contains all Swift source files
  - `Models/` - Data models and database interactions
  - `Views/` - User interface components
  - `Controllers/` - Business logic
  - `Utilities/` - Helper functions and extensions
- `Resources/` - Images, icons, and other assets

## Database

The application uses SQLite for data storage with the following schema:

- **Jobs** table - Stores job application information
- **Attachments** table - Stores document references linked to job applications

## iCloud Integration

The application uses CloudKit and iCloud document storage for:
- Syncing the SQLite database across devices
- Storing and syncing attached documents

## License

MIT 