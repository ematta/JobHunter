# JobHunter API Documentation

This document provides detailed information about the key APIs and components of the JobHunter application.

## DatabaseManager API

The `DatabaseManager` class provides methods for interacting with the SQLite database.

### Initialization

```swift
init()
```

Initializes a new DatabaseManager instance, sets up the database connection, and creates tables if they don't exist.

### Job Application Methods

```swift
func getAllJobs() -> [JobApplication]
```

Returns an array of all job applications in the database.

```swift
func getJob(id: Int) -> JobApplication?
```

Returns the job application with the specified ID, or nil if not found.

```swift
func addJob(companyName: String, jobTitle: String, applicationDate: Date, applicationDeadline: Date, status: String, jobDescription: String, notes: String, contactName: String, contactEmail: String, contactPhone: String) -> Int
```

Adds a new job application to the database and returns the ID of the newly created job.

```swift
func updateJob(id: Int, companyName: String, jobTitle: String, applicationDate: Date, applicationDeadline: Date, status: String, jobDescription: String, notes: String, contactName: String, contactEmail: String, contactPhone: String) -> Bool
```

Updates an existing job application in the database and returns true if successful.

```swift
func deleteJob(id: Int) -> Bool
```

Deletes the job application with the specified ID and returns true if successful.

```swift
func searchJobs(query: String) -> [JobApplication]
```

Searches for job applications matching the given query in company name, job title, or notes.

```swift
func filterJobsByStatus(status: String) -> [JobApplication]
```

Returns job applications with the specified status.

```swift
func filterJobsByDateRange(startDate: Date, endDate: Date, dateField: String) -> [JobApplication]
```

Returns job applications within the specified date range for the given date field (applicationDate or applicationDeadline).

### Attachment Methods

```swift
func getAttachmentsForJob(jobId: Int) -> [Attachment]
```

Returns all attachments associated with the specified job ID.

```swift
func addAttachment(jobId: Int, filePath: String) -> Int
```

Adds a new attachment to the database and returns the ID of the newly created attachment.

```swift
func deleteAttachment(id: Int) -> Bool
```

Deletes the attachment with the specified ID and returns true if successful.

### Database Maintenance

```swift
func backupDatabase() -> Bool
```

Creates a backup of the database and returns true if successful.

```swift
func restoreDatabase(fromBackup: String) -> Bool
```

Restores the database from a backup file and returns true if successful.

## AppController API

The `AppController` class serves as the main controller for the application.

```swift
static let shared = AppController()
```

Singleton instance of the AppController.

```swift
var databaseManager: DatabaseManager
```

Reference to the DatabaseManager instance.

```swift
func openMainWindow()
```

Opens the main application window.

```swift
func showNewJobForm()
```

Shows the form for creating a new job application.

```swift
func showEditJobForm(jobId: Int)
```

Shows the form for editing an existing job application.

```swift
func confirmDeleteJob(jobId: Int, completion: @escaping (Bool) -> Void)
```

Shows a confirmation dialog for deleting a job application.

## MainViewController API

The `MainViewController` controls the main window of the application.

```swift
func refreshJobList()
```

Refreshes the job application list from the database.

```swift
func selectJob(id: Int)
```

Selects the job application with the specified ID.

```swift
func setFilter(status: String?)
```

Sets the status filter for the job application list.

```swift
func setSearchQuery(query: String)
```

Sets the search query for the job application list.

```swift
func setDateRangeFilter(startDate: Date?, endDate: Date?, field: String)
```

Sets the date range filter for the job application list.

## NewJobViewController API

The `NewJobViewController` controls the form for creating and editing job applications.

```swift
init(jobId: Int? = nil)
```

Initializes a new instance for creating a new job application or editing an existing one if jobId is provided.

```swift
func validateForm() -> Bool
```

Validates the form inputs and returns true if all fields are valid.

```swift
func saveJob()
```

Saves the job application data to the database.

## Job Application Model

The `JobApplication` struct represents a job application in the system.

```swift
struct JobApplication {
    var id: Int
    var companyName: String
    var jobTitle: String
    var applicationDate: Date
    var applicationDeadline: Date
    var status: String
    var jobDescription: String
    var notes: String
    var contactName: String
    var contactEmail: String
    var contactPhone: String
    var attachments: [Attachment]
}
```

## Attachment Model

The `Attachment` struct represents a document attached to a job application.

```swift
struct Attachment {
    var id: Int
    var jobId: Int
    var filePath: String
}
```

## Status Enum

```swift
enum JobStatus: String, CaseIterable {
    case applied = "Applied"
    case interviewing = "Interviewing" 
    case rejected = "Rejected"
    case offer = "Offer"
}
```

## Data Export/Import API

```swift
func exportToCSV(path: String) -> Bool
```

Exports all job application data to a CSV file at the specified path.

```swift
func exportToJSON(path: String) -> Bool
```

Exports all job application data to a JSON file at the specified path.

```swift
func importFromCSV(path: String) -> Bool
```

Imports job application data from a CSV file at the specified path.

```swift
func importFromJSON(path: String) -> Bool
```

Imports job application data from a JSON file at the specified path. 