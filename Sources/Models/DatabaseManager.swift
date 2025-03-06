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
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dbURL = documentsDirectory.appendingPathComponent("JobHunter.sqlite")
        
        // Check if iCloud sync is enabled and use an appropriate location
        if let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").appendingPathComponent("JobHunter.sqlite") {
            print("Using iCloud for database storage at: \(iCloudURL)")
            
            // Create directory if needed
            let iCloudDirectory = iCloudURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: iCloudDirectory.path) {
                try fileManager.createDirectory(at: iCloudDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            db = try Connection(iCloudURL.path)
        } else {
            print("iCloud not available, using local storage at: \(dbURL)")
            db = try Connection(dbURL.path)
        }
        
        // Create tables if they don't exist
        try createTables()
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
        
        // Create jobs table
        try db.run(jobsTable.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(companyName)
            t.column(jobTitle)
            t.column(applicationDateStr)
            t.column(applicationDeadlineStr)
            t.column(status)
            t.column(jobDescription)
            t.column(notes)
            t.column(contactName)
            t.column(contactEmail)
            t.column(contactPhone)
        })
        
        // Create attachments table
        try db.run(attachmentsTable.create(ifNotExists: true) { t in
            t.column(attachmentId, primaryKey: true)
            t.column(jobIdFk)
            t.column(fileName)
            t.column(filePath)
            t.column(dateAddedStr)
            t.foreignKey(jobIdFk, references: jobsTable, id, delete: .cascade)
        })
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
     * Adds a new job application to the database.
     *
     * - Parameter jobApplication: The job application to add
     * - Returns: The ID of the newly created job application
     * - Throws: An error if the database operation fails
     */
    func addJobApplication(_ jobApplication: JobApplication) throws -> Int {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        let insert = jobsTable.insert(
            companyName <- jobApplication.companyName,
            jobTitle <- jobApplication.jobTitle,
            applicationDateStr <- dateToString(jobApplication.applicationDate),
            applicationDeadlineStr <- dateToString(jobApplication.applicationDeadline),
            status <- jobApplication.status,
            jobDescription <- jobApplication.jobDescription,
            notes <- jobApplication.notes,
            contactName <- jobApplication.contactName,
            contactEmail <- jobApplication.contactEmail,
            contactPhone <- jobApplication.contactPhone
        )
        
        let insertedId = try db.run(insert)
        return Int(insertedId)
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
                id: row[0] as! Int,
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
            let jobId = row[0] as! Int
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
                id: row[0] as! Int,
                jobId: row[1] as! Int,
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
     * Closes the database connection.
     *
     * This method is used to cleanly close the database connection when it is no longer needed.
     */
    func closeDatabase() {
        db = nil
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
} 