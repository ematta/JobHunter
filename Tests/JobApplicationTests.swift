import XCTest
@testable import JobHunter

final class JobApplicationTests: XCTestCase {
    
    func testJobApplicationInitialization() {
        let date = Date()
        let attachment = Attachment(
            id: 1, 
            jobId: 1, 
            fileName: "test.pdf",
            filePath: "test/path.pdf",
            dateAdded: date
        )
        
        let job = JobApplication(
            id: 1,
            companyName: "Test Company",
            jobTitle: "Software Engineer",
            applicationDate: date,
            applicationDeadline: date.addingTimeInterval(7 * 24 * 60 * 60), // 7 days later
            status: "Applied",
            jobDescription: "Test description",
            notes: "Test notes",
            contactName: "John Doe",
            contactEmail: "john@example.com",
            contactPhone: "123-456-7890",
            attachments: [attachment]
        )
        
        XCTAssertEqual(job.id, 1)
        XCTAssertEqual(job.companyName, "Test Company")
        XCTAssertEqual(job.jobTitle, "Software Engineer")
        XCTAssertEqual(job.applicationDate, date)
        XCTAssertEqual(job.status, "Applied")
        XCTAssertEqual(job.jobDescription, "Test description")
        XCTAssertEqual(job.notes, "Test notes")
        XCTAssertEqual(job.contactName, "John Doe")
        XCTAssertEqual(job.contactEmail, "john@example.com")
        XCTAssertEqual(job.contactPhone, "123-456-7890")
        XCTAssertEqual(job.attachments.count, 1)
        XCTAssertEqual(job.attachments[0].id, 1)
        XCTAssertEqual(job.attachments[0].jobId, 1)
        XCTAssertEqual(job.attachments[0].fileName, "test.pdf")
        XCTAssertEqual(job.attachments[0].filePath, "test/path.pdf")
    }
    
    func testJobStatusValidation() {
        // Test all valid statuses that should be supported
        let validStatuses = ["Applied", "Interviewing", "Rejected", "Offer"]
        
        // Create and check job applications with each valid status
        for status in validStatuses {
            let job = JobApplication(
                id: 1,
                companyName: "Test Company",
                jobTitle: "Software Engineer",
                applicationDate: Date(),
                applicationDeadline: Date().addingTimeInterval(7 * 24 * 60 * 60),
                status: status,
                jobDescription: "Test description",
                notes: "Test notes",
                contactName: "John Doe",
                contactEmail: "john@example.com",
                contactPhone: "123-456-7890",
                attachments: []
            )
            
            XCTAssertEqual(job.status, status)
        }
        
        // Test that we can still set any string as status (since it's not restricted by enum)
        let customStatus = "In Progress"
        let job = JobApplication(
            id: 1,
            companyName: "Test Company",
            jobTitle: "Software Engineer",
            applicationDate: Date(),
            applicationDeadline: Date().addingTimeInterval(7 * 24 * 60 * 60),
            status: customStatus,
            jobDescription: "Test description",
            notes: "Test notes",
            contactName: "John Doe",
            contactEmail: "john@example.com",
            contactPhone: "123-456-7890",
            attachments: []
        )
        
        XCTAssertEqual(job.status, customStatus)
    }
    
    static var allTests = [
        ("testJobApplicationInitialization", testJobApplicationInitialization),
        ("testJobStatusValidation", testJobStatusValidation)
    ]
} 