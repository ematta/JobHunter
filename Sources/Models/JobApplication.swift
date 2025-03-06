import Foundation

/**
 * Represents a job application in the system.
 *
 * This struct contains all information related to a job application, including
 * company details, application dates, status, and contact information.
 */
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
    
    /**
     * Initializes a new job application with the provided information.
     *
     * - Parameters:
     *   - id: The unique identifier for the job application
     *   - companyName: The name of the company
     *   - jobTitle: The title of the job position
     *   - applicationDate: The date when the application was submitted
     *   - applicationDeadline: The deadline for the application
     *   - status: The current status of the application (e.g., "Applied", "Interviewing", "Offered", "Rejected")
     *   - jobDescription: The description of the job
     *   - notes: Additional notes about the application
     *   - contactName: The name of the contact person at the company
     *   - contactEmail: The email address of the contact person
     *   - contactPhone: The phone number of the contact person
     *   - attachments: An array of attachments associated with this application
     */
    init(id: Int, companyName: String, jobTitle: String, applicationDate: Date, applicationDeadline: Date, status: String, jobDescription: String, notes: String, contactName: String, contactEmail: String, contactPhone: String, attachments: [Attachment]) {
        self.id = id
        self.companyName = companyName
        self.jobTitle = jobTitle
        self.applicationDate = applicationDate
        self.applicationDeadline = applicationDeadline
        self.status = status
        self.jobDescription = jobDescription
        self.notes = notes
        self.contactName = contactName
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.attachments = attachments
    }
} 