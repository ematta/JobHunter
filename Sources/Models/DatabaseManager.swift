import Foundation
import SQLite

/**
 * Manages database operations for the application.
 *
 * This class handles all database-related functionality, including connecting to the SQLite database,
 * creating tables, and performing CRUD operations on job applications and attachments.
 */
class DatabaseManager {
    private var db: Connection?
    
    // Tables
    private let jobsTable = Table("jobs")
    private let attachmentsTable = Table("attachments")
    
    // Jobs columns
    private let id = Expression<Int64>(value: "id")
    private let companyName = Expression<String>(value: "company_name")
    private let jobTitle = Expression<String>(value: "job_title")
    private let applicationDateStr = Expression<String>(value: "application_date")
    private let applicationDeadlineStr = Expression<String>(value: "application_deadline")
    private let status = Expression<String>(value: "status")
    private let jobDescription = Expression<String>(value: "job_description")
    private let notes = Expression<String>(value: "notes")
    private let contactName = Expression<String>(value: "contact_name")
    private let contactEmail = Expression<String>(value: "contact_email")
    private let contactPhone = Expression<String>(value: "contact_phone")
    private let url = Expression<String>(value: "url")
    
    // Attachments columns
    private let attachmentId = Expression<Int64>(value: "id")
    private let jobIdFk = Expression<Int64>(value: "job_id")
    private let fileName = Expression<String>(value: "file_name")
    private let filePath = Expression<String>(value: "file_path")
    private let dateAddedStr = Expression<String>(value: "date_added")
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    
    /**
     * Initializes the DatabaseManager and sets up the database.
     *
     * This method:
     * - Creates or opens the SQLite database file
     * - Determines the appropriate storage location (local or iCloud)
     * - Creates database tables if they don't exist
     *
     * - Throws: An error if database initialization fails
     */
    init() throws {
        // Create or open the database file
        let fileManager = FileManager.default
        
        // Try to use the Application Support directory first - better for databases than Documents
        let appSupportDir: URL
        do {
            appSupportDir = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            // Create a JobHunter directory within Application Support
            let jobHunterDir = appSupportDir.appendingPathComponent("JobHunter", isDirectory: true)
            
            if !fileManager.fileExists(atPath: jobHunterDir.path) {
                try fileManager.createDirectory(at: jobHunterDir, withIntermediateDirectories: true, attributes: nil)
            }
            
            let dbURL = jobHunterDir.appendingPathComponent("JobHunter.sqlite")
            print("Using Application Support for database storage at: \(dbURL.path)")
            
            // Check directory permissions
            print("Application Support directory permissions:")
            let task = Process()
            task.launchPath = "/bin/ls"
            task.arguments = ["-la", jobHunterDir.path]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.launch()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print(output)
            }
            
            // Try to connect to the database
            db = try Connection(dbURL.path)
            
            // Configure SQLite for better reliability
            try db?.execute("PRAGMA foreign_keys = ON")
            try db?.execute("PRAGMA journal_mode = WAL")
            try db?.execute("PRAGMA synchronous = NORMAL")
            
            print("Database successfully initialized in Application Support")
        } catch {
            print("Failed to use Application Support directory: \(error)")
            
            // Fall back to Documents directory
            do {
                let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let dbURL = documentsDirectory.appendingPathComponent("JobHunter.sqlite")
                
                print("Falling back to Documents directory at: \(dbURL.path)")
                // Check directory permissions
                print("Documents directory permissions:")
                let task = Process()
                task.launchPath = "/bin/ls"
                task.arguments = ["-la", documentsDirectory.path]
                let pipe = Pipe()
                task.standardOutput = pipe
                task.launch()
                
                // Make sure the directory is writable
                if !fileManager.isWritableFile(atPath: documentsDirectory.path) {
                    print("WARNING: Documents directory is not writable!")
                }
                
                db = try Connection(dbURL.path)
                try db?.execute("PRAGMA foreign_keys = ON")
                try db?.execute("PRAGMA journal_mode = WAL")
                
                print("Database initialized in Documents directory")
            } catch {
                print("Could not initialize database in typical locations: \(error)")
                
                // Last resort - use temporary directory which should always be writable
                let tempDir = fileManager.temporaryDirectory
                let tempDBPath = tempDir.appendingPathComponent("JobHunter_temp.sqlite")
                print("Using temporary directory as last resort: \(tempDBPath.path)")
                
                db = try Connection(tempDBPath.path)
                try db?.execute("PRAGMA foreign_keys = ON")
                
                print("WARNING: Using temporary directory for database. Data may be lost when application closes.")
            }
        }
        
        // Create tables if they don't exist
        try createTables()
        
        // Verify database is working with a quick test
        do {
            try db?.execute("SELECT 1")
            print("Database connection verified working")
        } catch {
            print("Database verification test failed: \(error)")
            throw error
        }
    }
    
    /**
     * Creates the database tables if they don't exist.
     *
     * Sets up the jobs and attachments tables with appropriate columns and relationships.
     *
     * - Throws: An error if table creation fails or the database is not initialized
     */
    private func createTables() throws {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        // Create jobs table using direct SQL rather than the query builder
        let createJobsTableSQL = """
        CREATE TABLE IF NOT EXISTS jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_name TEXT NOT NULL,
            job_title TEXT NOT NULL,
            application_date TEXT NOT NULL,
            application_deadline TEXT NOT NULL,
            status TEXT NOT NULL,
            job_description TEXT,
            notes TEXT,
            contact_name TEXT,
            contact_email TEXT,
            contact_phone TEXT,
            url TEXT
        )
        """
        
        print("Creating jobs table with SQL: \(createJobsTableSQL)")
        try db.execute(createJobsTableSQL)
        
        // Check if url column exists, if not add it
        do {
            let columnQuery = "PRAGMA table_info(jobs)"
            let columns = try db.prepare(columnQuery)
            var hasUrlColumn = false
            
            for column in columns {
                if let name = column[1] as? String, name == "url" {
                    hasUrlColumn = true
                    break
                }
            }
            
            if !hasUrlColumn {
                print("Adding url column to jobs table")
                try db.execute("ALTER TABLE jobs ADD COLUMN url TEXT")
            }
        } catch {
            print("Error checking for url column: \(error)")
        }
        
        // Create attachments table using direct SQL
        let createAttachmentsTableSQL = """
        CREATE TABLE IF NOT EXISTS attachments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_id INTEGER NOT NULL,
            file_name TEXT NOT NULL,
            file_path TEXT NOT NULL,
            date_added TEXT NOT NULL,
            FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
        )
        """
        
        print("Creating attachments table with SQL: \(createAttachmentsTableSQL)")
        try db.execute(createAttachmentsTableSQL)
        
        print("Tables created successfully")
    }
    
    /**
     * Converts a Date object to a string format suitable for database storage.
     *
     * - Parameter date: The Date object to convert
     * - Returns: A string representation of the date in the format "yyyy-MM-dd'T'HH:mm:ss"
     */
    private func dateToString(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    /**
     * Converts a date string from the database to a Date object.
     *
     * - Parameter string: The date string in the format "yyyy-MM-dd'T'HH:mm:ss"
     * - Returns: A Date object, or the current date if parsing fails
     */
    private func stringToDate(_ string: String) -> Date {
        // Early exit for empty strings
        if string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Date()
        }
        
        // Try the primary date format first
        if let date = dateFormatter.date(from: string) {
            return date
        }
        
        // Try alternate date formats if the primary format fails
        let alternateFormatters = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy/MM/dd"
        ]
        
        for format in alternateFormatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        // Default to current date if all parsing attempts fail
        print("Warning: Failed to parse date string: \(string). Using current date instead.")
        return Date()
    }
    
    /**
     * Sanitizes a string for safe database storage.
     *
     * Removes potentially problematic characters, trims whitespace,
     * and ensures the string doesn't exceed the maximum length.
     *
     * - Parameters:
     *   - string: The input string to sanitize
     *   - maxLength: The maximum allowed length (default: 255)
     * - Returns: The sanitized string
     */
    private func sanitizeString(_ string: String, maxLength: Int = 255) -> String {
        // Trim whitespace
        var sanitized = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove or replace potentially problematic characters
        sanitized = sanitized.replacingOccurrences(of: "'", with: "''") // Escape single quotes for SQL
        
        // Truncate if longer than maxLength
        if sanitized.count > maxLength {
            let endIndex = sanitized.index(sanitized.startIndex, offsetBy: maxLength)
            sanitized = String(sanitized[..<endIndex])
        }
        
        return sanitized
    }
    
    // MARK: - Job Application Methods
    
    /**
     * Adds a new job application to the database using direct SQL.
     *
     * - Parameter jobApplication: The job application to add
     * - Returns: The ID of the newly created job application
     * - Throws: An error if the database operation fails
     */
    func addJobApplication(_ jobApplication: JobApplication) throws -> Int {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        // Validate job application data before proceeding
        try validateJobApplication(jobApplication)
        
        print("Database path: \(db.description)")
        
        // Use transaction for atomicity
        var insertedId = -1
        
        try transaction {
            // Use performDatabaseOperation for better error handling
            insertedId = try performDatabaseOperation(operation: "add job application") {
                // Verify database and table
                let tableCheck = "SELECT name FROM sqlite_master WHERE type='table' AND name='jobs'"
                let tableExists = try db.scalar(tableCheck) as? String != nil
                print("Jobs table exists: \(tableExists)")
                
                if !tableExists {
                    print("Jobs table doesn't exist. Attempting to create it...")
                    try createTables()
                }
                
                // Print schema info
                print("Checking table schema...")
                let schemaQuery = "PRAGMA table_info(jobs)"
                let schemaRows = try db.prepare(schemaQuery)
                for row in schemaRows {
                    if let colName = row[1] as? String, let colType = row[2] as? String {
                        print("Column: \(colName) (type: \(colType), notNull: \((row[3] as? Int64 ?? 0) == 1))")
                    }
                }
                
                // Format date values
                let appDateStr = dateToString(jobApplication.applicationDate)
                let deadlineDateStr = dateToString(jobApplication.applicationDeadline)
                
                // Use very simple approach to insert data
                print("Creating insert statement...")
                let insertSQL = """
                INSERT INTO jobs (company_name, job_title, application_date, application_deadline, status, 
                                  job_description, notes, contact_name, contact_email, contact_phone, url)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """
                
                print("Binding parameters...")
                let statement = try db.prepare(insertSQL)
                
                // Execute with careful error handling
                print("Executing insert with parameters:")
                print("- Company: \(jobApplication.companyName)")
                print("- Title: \(jobApplication.jobTitle)")
                print("- App Date: \(appDateStr)")
                print("- Deadline: \(deadlineDateStr)")
                print("- Status: \(jobApplication.status)")
                print("- URL: \(jobApplication.url)")
                
                try statement.run(
                    sanitizeString(jobApplication.companyName.isEmpty ? "" : jobApplication.companyName),
                    sanitizeString(jobApplication.jobTitle.isEmpty ? "" : jobApplication.jobTitle),
                    appDateStr,
                    deadlineDateStr,
                    sanitizeString(jobApplication.status.isEmpty ? "Applied" : jobApplication.status),
                    sanitizeString(jobApplication.jobDescription.isEmpty ? "" : jobApplication.jobDescription, maxLength: 2000),
                    sanitizeString(jobApplication.notes.isEmpty ? "" : jobApplication.notes, maxLength: 2000),
                    sanitizeString(jobApplication.contactName.isEmpty ? "" : jobApplication.contactName),
                    sanitizeString(jobApplication.contactEmail.isEmpty ? "" : jobApplication.contactEmail),
                    sanitizeString(jobApplication.contactPhone.isEmpty ? "" : jobApplication.contactPhone),
                    sanitizeString(jobApplication.url.isEmpty ? "" : jobApplication.url)
                )
                
                // Get inserted ID
                let newId = Int(db.lastInsertRowid)
                print("Insert successful! New job ID: \(newId)")
                return newId
            }
        }
        
        return insertedId
    }
    
    /**
     * Updates an existing job application in the database.
     *
     * - Parameter jobApplication: The job application with updated information
     * - Throws: An error if the update fails or the database is not initialized
     */
    func updateJobApplication(_ jobApplication: JobApplication) throws {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        // Validate job application data before proceeding
        try validateJobApplication(jobApplication)
        
        // Use a raw SQL query instead of the filter method
        let sql = "UPDATE jobs SET company_name = ?, job_title = ?, application_date = ?, application_deadline = ?, status = ?, job_description = ?, notes = ?, contact_name = ?, contact_email = ?, contact_phone = ?, url = ? WHERE id = ?"
        
        // Prepare values with additional safety checks
        let companyNameValue = sanitizeString(jobApplication.companyName.isEmpty ? "" : jobApplication.companyName)
        let jobTitleValue = sanitizeString(jobApplication.jobTitle.isEmpty ? "" : jobApplication.jobTitle)
        let appDateValue = dateToString(jobApplication.applicationDate)
        let deadlineValue = dateToString(jobApplication.applicationDeadline)
        let statusValue = sanitizeString(jobApplication.status.isEmpty ? "Applied" : jobApplication.status)
        let jobDescriptionValue = sanitizeString(jobApplication.jobDescription.isEmpty ? "" : jobApplication.jobDescription, maxLength: 2000)
        let notesValue = sanitizeString(jobApplication.notes.isEmpty ? "" : jobApplication.notes, maxLength: 2000)
        let contactNameValue = sanitizeString(jobApplication.contactName.isEmpty ? "" : jobApplication.contactName)
        let contactEmailValue = sanitizeString(jobApplication.contactEmail.isEmpty ? "" : jobApplication.contactEmail)
        let contactPhoneValue = sanitizeString(jobApplication.contactPhone.isEmpty ? "" : jobApplication.contactPhone)
        let urlValue = sanitizeString(jobApplication.url.isEmpty ? "" : jobApplication.url)
        
        let stmt = try db.prepare(sql)
        try stmt.run(
            companyNameValue,
            jobTitleValue,
            appDateValue,
            deadlineValue,
            statusValue,
            jobDescriptionValue,
            notesValue,
            contactNameValue,
            contactEmailValue,
            contactPhoneValue,
            urlValue,
            jobApplication.id
        )
        
        print("Updated job application: \(jobApplication.id)")
    }
    
    /**
     * Deletes a job application from the database.
     *
     * - Parameter jobId: The ID of the job application to delete
     * - Throws: An error if the deletion fails or the database is not initialized
     */
    func deleteJobApplication(_ jobId: Int) throws {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        // Use a raw SQL query instead of the filter method
        let sql = "DELETE FROM jobs WHERE id = ?"
        
        let stmt = try db.prepare(sql)
        try stmt.run(jobId)
        
        print("Deleted job application: \(jobId)")
    }
    
    /**
     * Retrieves a specific job application from the database.
     *
     * - Parameter jobId: The ID of the job application to retrieve
     * - Returns: The job application if found, nil otherwise
     * - Throws: An error if the database operation fails
     */
    func getJobApplication(_ jobId: Int) throws -> JobApplication? {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        // Use a raw SQL query instead of the filter method
        let sql = "SELECT * FROM jobs WHERE id = ?"
        
        let stmt = try db.prepare(sql)
        
        for row in try stmt.run(jobId) {
            let attachments = try getAttachmentsForJob(jobId)
            
            return JobApplication(
                id: Int(row[0] as? Int64 ?? 0),
                companyName: row[1] as? String ?? "",
                jobTitle: row[2] as? String ?? "",
                applicationDate: stringToDate(row[3] as? String ?? ""),
                applicationDeadline: stringToDate(row[4] as? String ?? ""),
                status: row[5] as? String ?? "",
                jobDescription: row[6] as? String ?? "",
                notes: row[7] as? String ?? "",
                contactName: row[8] as? String ?? "",
                contactEmail: row[9] as? String ?? "",
                contactPhone: row[10] as? String ?? "",
                url: row[11] as? String ?? "",
                attachments: attachments
            )
        }
        
        return nil
    }
    
    /**
     * Retrieves all job applications from the database.
     *
     * - Returns: An array of all job applications, sorted by application date in descending order
     * - Throws: An error if the database operation fails
     */
    func getAllJobApplications() throws -> [JobApplication] {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        var jobApplications: [JobApplication] = []
        
        // Use a raw SQL query instead of the filter method
        let sql = "SELECT * FROM jobs ORDER BY application_date DESC"
        
        let stmt = try db.prepare(sql)
        
        for row in try stmt.run() {
            let jobId = Int(row[0] as? Int64 ?? 0)
            let attachments = try getAttachmentsForJob(jobId)
            
            let jobApplication = JobApplication(
                id: jobId,
                companyName: row[1] as? String ?? "",
                jobTitle: row[2] as? String ?? "",
                applicationDate: stringToDate(row[3] as? String ?? ""),
                applicationDeadline: stringToDate(row[4] as? String ?? ""),
                status: row[5] as? String ?? "",
                jobDescription: row[6] as? String ?? "",
                notes: row[7] as? String ?? "",
                contactName: row[8] as? String ?? "",
                contactEmail: row[9] as? String ?? "",
                contactPhone: row[10] as? String ?? "",
                url: row[11] as? String ?? "",
                attachments: attachments
            )
            
            jobApplications.append(jobApplication)
        }
        
        return jobApplications
    }
    
    // MARK: - Attachment Methods
    
    /**
     * Adds a new attachment to the database.
     *
     * - Parameter attachment: The attachment to add
     * - Returns: The ID of the newly created attachment
     * - Throws: An error if the database operation fails
     */
    func addAttachment(_ attachment: Attachment) throws -> Int {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        // Use a raw SQL query instead of the insert method
        let sql = "INSERT INTO attachments (job_id, file_name, file_path, date_added) VALUES (?, ?, ?, ?)"
        
        let stmt = try db.prepare(sql)
        try stmt.run(
            attachment.jobId,
            attachment.fileName,
            attachment.filePath,
            dateToString(attachment.dateAdded)
        )
        
        return Int(db.lastInsertRowid)
    }
    
    /**
     * Deletes an attachment from the database.
     *
     * - Parameter attachmentId: The ID of the attachment to delete
     * - Throws: An error if the deletion fails or the database is not initialized
     */
    func deleteAttachment(_ attachmentId: Int) throws {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        // Use a raw SQL query instead of the filter method
        let sql = "DELETE FROM attachments WHERE id = ?"
        
        let stmt = try db.prepare(sql)
        try stmt.run(attachmentId)
        
        print("Deleted attachment: \(attachmentId)")
    }
    
    /**
     * Retrieves all attachments associated with a specific job application.
     *
     * - Parameter jobId: The ID of the job application
     * - Returns: An array of attachments for the specified job
     * - Throws: An error if the database operation fails
     */
    func getAttachmentsForJob(_ jobId: Int) throws -> [Attachment] {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        var attachments: [Attachment] = []
        
        // Use a raw SQL query instead of the filter method
        let sql = "SELECT * FROM attachments WHERE job_id = ?"
        
        let stmt = try db.prepare(sql)
        
        for row in try stmt.run(jobId) {
            let attachment = Attachment(
                id: Int(row[0] as? Int64 ?? 0),
                jobId: Int(row[1] as? Int64 ?? 0),
                fileName: row[2] as? String ?? "",
                filePath: row[3] as? String ?? "",
                dateAdded: stringToDate(row[4] as? String ?? "")
            )
            
            attachments.append(attachment)
        }
        
        return attachments
    }
    
    // MARK: - Utility Methods
    
    /**
     * Executes database operations within a transaction.
     *
     * - Parameter block: A closure containing the database operations to execute within the transaction
     * - Throws: An error if the transaction fails or if any operation within the transaction fails
     */
    func transaction(_ block: () throws -> Void) throws {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        print("Beginning database transaction...")
        
        // Use proper transaction handling
        do {
            try db.execute("BEGIN IMMEDIATE TRANSACTION")
            
            do {
                try block()
                try db.execute("COMMIT TRANSACTION")
                print("Transaction committed successfully")
            } catch {
                // Try to roll back on error
                print("Error in transaction, attempting rollback: \(error)")
                do {
                    try db.execute("ROLLBACK TRANSACTION")
                    print("Transaction rolled back")
                } catch {
                    print("Failed to roll back transaction: \(error)")
                }
                throw error
            }
        } catch {
            print("Transaction failed: \(error)")
            throw error
        }
    }
    
    /**
     * Closes the database connection.
     *
     * This method is used to cleanly close the database connection when it is no longer needed.
     */
    func closeDatabase() {
        db = nil
    }
    
    /**
     * Completely resets the database by dropping all tables and recreating them.
     * WARNING: This will delete all data in the database.
     *
     * - Throws: An error if the reset operation fails
     */
    func resetDatabase() throws {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        print("Resetting database...")
        
        // Check if tables exist before dropping
        let jobsTableExists = try db.scalar("SELECT name FROM sqlite_master WHERE type='table' AND name='jobs'") as? String != nil
        let attachmentsTableExists = try db.scalar("SELECT name FROM sqlite_master WHERE type='table' AND name='attachments'") as? String != nil
        
        // Drop tables if they exist
        if attachmentsTableExists {
            print("Dropping attachments table...")
            try db.execute("DROP TABLE IF EXISTS attachments")
        }
        
        if jobsTableExists {
            print("Dropping jobs table...")
            try db.execute("DROP TABLE IF EXISTS jobs")
        }
        
        // Recreate tables
        print("Recreating tables...")
        try createTables()
        
        print("Database reset completed successfully")
    }
    
    /**
     * Attempts to create a new database connection at a different location
     * as a fallback in case there are permission issues with the primary location.
     *
     * - Returns: true if successful, false otherwise
     */
    func tryAlternativeDatabaseLocation() -> Bool {
        print("Attempting to use alternative database location...")
        
        do {
            // First, try the cache directory which should be reliable
            let cacheDir = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let cacheDBPath = cacheDir.appendingPathComponent("JobHunter.sqlite")
            
            print("Trying cache directory for database at: \(cacheDBPath.path)")
            
            // Create new connection with proper configuration
            db = try Connection(cacheDBPath.path)
            try db?.execute("PRAGMA foreign_keys = ON")
            try db?.execute("PRAGMA journal_mode = WAL")
            try db?.execute("PRAGMA synchronous = NORMAL")
            
            // Recreate tables
            try createTables()
            
            // Verify by adding a test record and then deleting it
            print("Verifying database with test write operation...")
            let insertSQL = "INSERT INTO jobs (company_name, job_title, application_date, application_deadline, status, job_description, notes, contact_name, contact_email, contact_phone, url) VALUES ('Test Company', 'Test Job', '2023-01-01T12:00:00', '2023-01-01T12:00:00', 'Test', '', '', '', '', '', '')"
            
            guard let db = db else { return false }
            
            try db.execute(insertSQL)
            let testId = db.lastInsertRowid
            
            // Delete the test record
            let deleteSQL = "DELETE FROM jobs WHERE id = ?"
            let deleteStmt = try db.prepare(deleteSQL)
            try deleteStmt.run(testId)
            
            print("Alternative database in cache directory setup successfully!")
            return true
        } catch {
            print("Failed to set up database in cache directory: \(error)")
            
            // As a last resort, use the temporary directory
            do {
                let tempDir = FileManager.default.temporaryDirectory
                let tempDBPath = tempDir.appendingPathComponent("JobHunter_temp.sqlite")
                print("Using temporary directory as last resort: \(tempDBPath.path)")
                
                db = try Connection(tempDBPath.path)
                try db?.execute("PRAGMA foreign_keys = ON")
                try db?.execute("PRAGMA journal_mode = WAL")
                
                // Recreate tables
                try createTables()
                
                print("Alternative database in temporary directory setup successfully!")
                print("WARNING: Data in temporary directory may be lost when the application closes")
                return true
            } catch {
                print("Failed to set up alternative database in temporary directory: \(error)")
                return false
            }
        }
    }
    
    /**
     * Validates a job application's data for integrity.
     *
     * - Parameter jobApplication: The job application to validate
     * - Throws: ValidationError if any required field is invalid
     */
    private func validateJobApplication(_ jobApplication: JobApplication) throws {
        // Validate required fields
        guard !jobApplication.companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("Company Name")
        }
        
        guard !jobApplication.jobTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("Job Title")
        }
        
        // Ensure dates are valid (not in the far past or future)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        // Application date should be within a reasonable range
        let appDateYear = calendar.component(.year, from: jobApplication.applicationDate)
        guard appDateYear >= (currentYear - 5) && appDateYear <= (currentYear + 1) else {
            throw ValidationError.invalidDateRange("Application Date")
        }
        
        // Validate email format if provided
        if !jobApplication.contactEmail.isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            guard emailPredicate.evaluate(with: jobApplication.contactEmail) else {
                throw ValidationError.invalidFormat("Contact Email")
            }
        }
        
        // Validate URL format if provided
        if !jobApplication.url.isEmpty {
            guard URL(string: jobApplication.url) != nil else {
                throw ValidationError.invalidFormat("URL")
            }
        }
        
        // Validate phone number format if provided
        if !jobApplication.contactPhone.isEmpty {
            let phoneRegex = "^[+]?[(]?[0-9]{1,4}[)]?[-\\s\\./0-9]*$"
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            guard phonePredicate.evaluate(with: jobApplication.contactPhone) else {
                throw ValidationError.invalidFormat("Contact Phone")
            }
        }
    }
    
    /**
     * Performs a database operation with robust error handling and logging.
     *
     * - Parameters:
     *   - operation: The operation name for logging purposes
     *   - action: The closure containing the database operation to perform
     * - Throws: Rethrows any errors from the database operation with additional context
     * - Returns: The result of the database operation
     */
    private func performDatabaseOperation<T>(operation: String, action: () throws -> T) throws -> T {
        do {
            return try action()
        } catch {
            // Log the error
            print("Error during database operation '\(operation)': \(error.localizedDescription)")
            
            // Convert to appropriate domain error
            if error.localizedDescription.contains("constraint") {
                throw DatabaseError.insertFailed(message: "Constraint violation: \(error.localizedDescription)")
            } else if error.localizedDescription.contains("readonly") {
                throw DatabaseError.updateFailed
            } else if error.localizedDescription.contains("no such table") {
                // Try to recover by recreating tables
                do {
                    try createTables()
                    // Try the operation once more
                    return try action()
                } catch {
                    throw DatabaseError.insertFailed(message: "Table creation failed: \(error.localizedDescription)")
                }
            } else {
                // Propagate the error with more context
                throw DatabaseError.insertFailed(message: "Database operation failed: \(error.localizedDescription)")
            }
        }
    }
}

/**
 * Errors that can occur during database operations.
 */
enum DatabaseError: Error {
    /// The database connection is not initialized
    case databaseNotInitialized
    /// An update operation failed
    case updateFailed
    /// A delete operation failed
    case deleteFailed
    /// An insert operation failed
    case insertFailed(message: String)
}

/**
 * Errors that can occur during data validation.
 */
enum ValidationError: Error {
    /// A required field is missing or empty
    case missingRequiredField(_ fieldName: String)
    /// A field has an invalid format
    case invalidFormat(_ fieldName: String)
    /// A date is outside the valid range
    case invalidDateRange(_ fieldName: String)
    /// A field exceeds the maximum allowed length
    case fieldTooLong(_ fieldName: String, maxLength: Int)
} 