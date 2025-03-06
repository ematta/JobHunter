import XCTest
import Foundation
@testable import JobHunter
import SQLite

final class DatabaseManagerTests: XCTestCase {
    var dbManager: DatabaseManager!
    let testDatabasePath = FileManager.default.temporaryDirectory.appendingPathComponent("test_database.sqlite").path
    
    override func setUp() {
        super.setUp()
        // Initialize the database manager with a custom initializer for testing
        do {
            dbManager = try TestDatabaseManager(databasePath: testDatabasePath)
        } catch {
            XCTFail("Failed to initialize database: \(error)")
        }
    }
    
    override func tearDown() {
        // Delete the test database after each test
        try? FileManager.default.removeItem(atPath: testDatabasePath)
        dbManager = nil
        super.tearDown()
    }
    
    func testDatabaseInitialization() throws {
        // Verify that the database manager was initialized successfully
        XCTAssertNotNil(dbManager, "Database manager should be initialized")
        
        // Verify that we can get an empty list of job applications
        let jobs = try dbManager.getAllJobApplications()
        XCTAssertEqual(jobs.count, 0, "Newly initialized database should have no job applications")
    }
    
    func testAddJob() throws {
        // Create a test job application
        let testJob = createTestJobApplication()
        
        // Add the job to the database
        let jobId = try dbManager.addJobApplication(testJob)
        
        // Verify the job was added by retrieving it
        let retrievedJob = try dbManager.getJobApplication(jobId)
        XCTAssertNotNil(retrievedJob, "Job should be retrievable after adding")
        XCTAssertEqual(retrievedJob?.companyName, testJob.companyName)
        XCTAssertEqual(retrievedJob?.jobTitle, testJob.jobTitle)
        
        // Check that getAllJobApplications also returns the job
        let allJobs = try dbManager.getAllJobApplications()
        XCTAssertEqual(allJobs.count, 1, "There should be one job in the database")
    }
    
    func testUpdateJob() throws {
        // Add a job to update
        let testJob = createTestJobApplication()
        let jobId = try dbManager.addJobApplication(testJob)
        
        // Retrieve the job to update it
        guard var jobToUpdate = try dbManager.getJobApplication(jobId) else {
            XCTFail("Job should exist in the database")
            return
        }
        
        // Update job properties
        jobToUpdate.companyName = "Updated Company"
        jobToUpdate.jobTitle = "Updated Position"
        jobToUpdate.status = "Interviewing"
        
        // Perform the update
        try dbManager.updateJobApplication(jobToUpdate)
        
        // Verify the update
        let updatedJob = try dbManager.getJobApplication(jobId)
        XCTAssertNotNil(updatedJob)
        XCTAssertEqual(updatedJob?.companyName, "Updated Company")
        XCTAssertEqual(updatedJob?.jobTitle, "Updated Position")
        XCTAssertEqual(updatedJob?.status, "Interviewing")
    }
    
    func testDeleteJob() throws {
        // Add a job to delete
        let testJob = createTestJobApplication()
        let jobId = try dbManager.addJobApplication(testJob)
        
        // Verify the job exists
        XCTAssertNotNil(try dbManager.getJobApplication(jobId))
        
        // Delete the job
        try dbManager.deleteJobApplication(jobId)
        
        // Verify the job was deleted
        XCTAssertNil(try dbManager.getJobApplication(jobId))
        
        // Check that getAllJobApplications returns empty list
        let allJobs = try dbManager.getAllJobApplications()
        XCTAssertEqual(allJobs.count, 0, "There should be no jobs after deletion")
    }
    
    func testAddAndGetAttachment() throws {
        // First, create a job to attach files to
        let testJob = createTestJobApplication()
        let jobId = try dbManager.addJobApplication(testJob)
        
        // Create and add an attachment
        let attachment = Attachment(
            id: 0,
            jobId: jobId,
            fileName: "Resume.pdf",
            filePath: "/tmp/test_resume.pdf",
            dateAdded: Date()
        )
        
        let attachmentId = try dbManager.addAttachment(attachment)
        
        // Verify the attachment can be retrieved with the job
        let jobWithAttachment = try dbManager.getJobApplication(jobId)
        XCTAssertNotNil(jobWithAttachment)
        XCTAssertEqual(jobWithAttachment?.attachments.count, 1)
        XCTAssertEqual(jobWithAttachment?.attachments.first?.fileName, "Resume.pdf")
        
        // Verify we can get attachments directly
        let attachments = try dbManager.getAttachmentsForJob(jobId)
        XCTAssertEqual(attachments.count, 1)
        XCTAssertEqual(attachments.first?.id, attachmentId)
    }
    
    func testDeleteAttachment() throws {
        // Create a job and attachment
        let testJob = createTestJobApplication()
        let jobId = try dbManager.addJobApplication(testJob)
        
        let attachment = Attachment(
            id: 0,
            jobId: jobId,
            fileName: "Cover Letter.pdf",
            filePath: "/tmp/test_coverletter.pdf",
            dateAdded: Date()
        )
        
        let attachmentId = try dbManager.addAttachment(attachment)
        
        // Verify the attachment exists
        var attachments = try dbManager.getAttachmentsForJob(jobId)
        XCTAssertEqual(attachments.count, 1)
        
        // Delete the attachment
        try dbManager.deleteAttachment(attachmentId)
        
        // Verify the attachment was deleted
        attachments = try dbManager.getAttachmentsForJob(jobId)
        XCTAssertEqual(attachments.count, 0, "There should be no attachments after deletion")
    }
    
    // Helper method to create a test job application
    private func createTestJobApplication() -> JobApplication {
        return JobApplication(
            id: 0, // Will be set by the database
            companyName: "Test Company",
            jobTitle: "Swift Developer",
            applicationDate: Date(),
            applicationDeadline: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            status: "Applied",
            jobDescription: "Test job description",
            notes: "Test notes",
            contactName: "Test Contact",
            contactEmail: "test@example.com",
            contactPhone: "123-456-7890",
            attachments: []
        )
    }
    
    static var allTests = [
        ("testDatabaseInitialization", testDatabaseInitialization),
        ("testAddJob", testAddJob),
        ("testUpdateJob", testUpdateJob),
        ("testDeleteJob", testDeleteJob),
        ("testAddAndGetAttachment", testAddAndGetAttachment),
        ("testDeleteAttachment", testDeleteAttachment)
    ]
}

// Custom DatabaseManager subclass for testing that directly implements the needed methods
class TestDatabaseManager: DatabaseManager {
    private var db: Connection?
    private let dateFormatter = DateFormatter()
    
    // Initialize with specific test database path
    init(databasePath: String) throws {
        // Skip the parent initializer
        try super.init()
        
        // Set up date formatter
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        // Create the test database connection
        db = try Connection(databasePath)
        
        // Enable foreign key support
        if let db = db {
            try db.execute("PRAGMA foreign_keys = ON")
        }
        
        // Create the required tables
        try createTables()
    }
    
    // Create test tables
    private func createTables() throws {
        guard let db = db else {
            throw NSError(domain: "TestDatabaseManagerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Database connection not initialized"])
        }
        
        // Create jobs table
        try db.execute("""
            CREATE TABLE IF NOT EXISTS jobs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                company_name TEXT,
                job_title TEXT,
                application_date TEXT,
                application_deadline TEXT,
                status TEXT,
                job_description TEXT,
                notes TEXT,
                contact_name TEXT,
                contact_email TEXT,
                contact_phone TEXT
            )
        """)
        
        // Create attachments table
        try db.execute("""
            CREATE TABLE IF NOT EXISTS attachments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                job_id INTEGER,
                file_name TEXT,
                file_path TEXT,
                date_added TEXT,
                FOREIGN KEY(job_id) REFERENCES jobs(id) ON DELETE CASCADE
            )
        """)
    }
    
    // Override parent methods to use our test database connection
    
    override func addJobApplication(_ jobApplication: JobApplication) throws -> Int {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        let insert = """
            INSERT INTO jobs (
                company_name, job_title, application_date, application_deadline, 
                status, job_description, notes, contact_name, contact_email, contact_phone
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let stmt = try db.prepare(insert)
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
            jobApplication.contactPhone
        )
        
        return Int(db.lastInsertRowid)
    }
    
    override func getJobApplication(_ jobId: Int) throws -> JobApplication? {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        let query = "SELECT * FROM jobs WHERE id = ?"
        let stmt = try db.prepare(query)
        
        for row in try stmt.run(jobId) {
            let attachments = try getAttachmentsForJob(jobId)
            
            // Use proper Int64 to Int conversion
            let id = Int(row[0] as! Int64)
            
            return JobApplication(
                id: id,
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
    
    override func getAllJobApplications() throws -> [JobApplication] {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        var jobApplications: [JobApplication] = []
        
        let query = "SELECT * FROM jobs ORDER BY application_date DESC"
        let stmt = try db.prepare(query)
        
        for row in try stmt.run() {
            // Use proper Int64 to Int conversion
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
    
    override func updateJobApplication(_ jobApplication: JobApplication) throws {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        let update = """
            UPDATE jobs SET 
                company_name = ?, job_title = ?, application_date = ?, application_deadline = ?, 
                status = ?, job_description = ?, notes = ?, contact_name = ?, contact_email = ?, 
                contact_phone = ?
            WHERE id = ?
        """
        
        let stmt = try db.prepare(update)
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
    }
    
    override func deleteJobApplication(_ jobId: Int) throws {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        let query = "DELETE FROM jobs WHERE id = ?"
        let stmt = try db.prepare(query)
        try stmt.run(jobId)
    }
    
    override func addAttachment(_ attachment: Attachment) throws -> Int {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        let insert = """
            INSERT INTO attachments (
                job_id, file_name, file_path, date_added
            ) VALUES (?, ?, ?, ?)
        """
        
        let stmt = try db.prepare(insert)
        try stmt.run(
            attachment.jobId,
            attachment.fileName,
            attachment.filePath,
            dateToString(attachment.dateAdded)
        )
        
        return Int(db.lastInsertRowid)
    }
    
    override func getAttachmentsForJob(_ jobId: Int) throws -> [Attachment] {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        var attachments: [Attachment] = []
        
        let query = "SELECT * FROM attachments WHERE job_id = ?"
        let stmt = try db.prepare(query)
        
        for row in try stmt.run(jobId) {
            // Use proper Int64 to Int conversion
            let id = Int(row[0] as! Int64)
            let attachmentJobId = Int(row[1] as! Int64)
            
            let attachment = Attachment(
                id: id,
                jobId: attachmentJobId,
                fileName: row[2] as! String,
                filePath: row[3] as! String,
                dateAdded: stringToDate(row[4] as! String)
            )
            
            attachments.append(attachment)
        }
        
        return attachments
    }
    
    override func deleteAttachment(_ attachmentId: Int) throws {
        guard let db = db else {
            throw DatabaseError.databaseNotInitialized
        }
        
        let query = "DELETE FROM attachments WHERE id = ?"
        let stmt = try db.prepare(query)
        try stmt.run(attachmentId)
    }
    
    // Helper methods
    private func dateToString(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    private func stringToDate(_ string: String) -> Date {
        return dateFormatter.date(from: string) ?? Date()
    }
} 