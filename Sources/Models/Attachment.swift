import Foundation

/**
 * Represents a file attachment associated with a job application.
 *
 * This struct models a file attachment that can be added to a job application,
 * such as resumes, cover letters, or other relevant documents.
 */
struct Attachment: Identifiable, Codable, Hashable {
    var id: Int
    var jobId: Int
    var fileName: String
    var filePath: String
    var dateAdded: Date
    
    /**
     * Initializes a new attachment with the provided information.
     *
     * - Parameters:
     *   - id: The unique identifier for the attachment
     *   - jobId: The identifier of the job application this attachment belongs to
     *   - fileName: The name of the attached file
     *   - filePath: The path where the file is stored
     *   - dateAdded: The date when the attachment was added
     */
    init(id: Int, jobId: Int, fileName: String, filePath: String, dateAdded: Date) {
        self.id = id
        self.jobId = jobId
        self.fileName = fileName
        self.filePath = filePath
        self.dateAdded = dateAdded
    }
} 