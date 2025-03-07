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
            contact_phone TEXT
        )
        """
        
        print("Creating jobs table with SQL: \(createJobsTableSQL)")
        try db.execute(createJobsTableSQL)
        
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
        return dateFormatter.date(from: string) ?? Date()
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
        
        print("Database path: \(db.description)")
        
        // Use transaction for atomicity
        var insertedId = -1
        
        try transaction {
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
                print("Column: \(row[1] as! String) (type: \(row[2] as! String), notNull: \((row[3] as! Int64) == 1))")
            }
            
            // Format date values
            let appDateStr = dateToString(jobApplication.applicationDate)
            let deadlineDateStr = dateToString(jobApplication.applicationDeadline)
            
            // Use very simple approach to insert data
            print("Creating insert statement...")
            let insertSQL = """
            INSERT INTO jobs (company_name, job_title, application_date, application_deadline, status, 
                              job_description, notes, contact_name, contact_email, contact_phone)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
            
            try statement.run(
                jobApplication.companyName.isEmpty ? "" : jobApplication.companyName,
                jobApplication.jobTitle.isEmpty ? "" : jobApplication.jobTitle,
                appDateStr,
                deadlineDateStr,
                jobApplication.status.isEmpty ? "Applied" : jobApplication.status,
                jobApplication.jobDescription.isEmpty ? "" : jobApplication.jobDescription,
                jobApplication.notes.isEmpty ? "" : jobApplication.notes,
                jobApplication.contactName.isEmpty ? "" : jobApplication.contactName,
                jobApplication.contactEmail.isEmpty ? "" : jobApplication.contactEmail,
                jobApplication.contactPhone.isEmpty ? "" : jobApplication.contactPhone
            )
            
            // Get inserted ID
            insertedId = Int(db.lastInsertRowid)
            print("Insert successful! New job ID: \(insertedId)")
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
        
        // Use a raw SQL query instead of the filter method
        let sql = "UPDATE jobs SET company_name = ?, job_title = ?, application_date = ?, application_deadline = ?, status = ?, job_description = ?, notes = ?, contact_name = ?, contact_email = ?, contact_phone = ? WHERE id = ?"
        
        let stmt = try db.prepare(sql)
        try stmt.run(
            jobApplication.companyName,
            jobApplication.jobTitle,
            dateToString(jobApplication.applicationDate),
            dateToString(jobApplication.applicationDeadline),
            jobApplication.status,
            jobApplication.jobDescription,
            jobApplication.notes,
            jobApplication.contactName,
            jobApplication.contactEmail,
            jobApplication.contactPhone,
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
                id: Int(row[0] as! Int64),
                companyName: row[1] as! String,
                jobTitle: row[2] as! String,
                applicationDate: stringToDate(row[3] as! String),
                applicationDeadline: stringToDate(row[4] as! String),
                status: row[5] as! String,
                jobDescription: row[6] as! String,
                notes: row[7] as! String,
                contactName: row[8] as! String,
                contactEmail: row[9] as! String,
                contactPhone: row[10] as! String,
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
            let jobId = Int(row[0] as! Int64)
            let attachments = try getAttachmentsForJob(jobId)
            
            let jobApplication = JobApplication(
                id: jobId,
                companyName: row[1] as! String,
                jobTitle: row[2] as! String,
                applicationDate: stringToDate(row[3] as! String),
                applicationDeadline: stringToDate(row[4] as! String),
                status: row[5] as! String,
                jobDescription: row[6] as! String,
                notes: row[7] as! String,
                contactName: row[8] as! String,
                contactEmail: row[9] as! String,
                contactPhone: row[10] as! String,
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
                id: Int(row[0] as! Int64),
                jobId: Int(row[1] as! Int64),
                fileName: row[2] as! String,
                filePath: row[3] as! String,
                dateAdded: stringToDate(row[4] as! String)
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
            let insertSQL = "INSERT INTO jobs (company_name, job_title, application_date, application_deadline, status, job_description, notes, contact_name, contact_email, contact_phone) VALUES ('Test Company', 'Test Job', '2023-01-01T12:00:00', '2023-01-01T12:00:00', 'Test', '', '', '', '', '')"
            
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