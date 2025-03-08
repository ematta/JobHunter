import Foundation
@testable import JobHunter

/// A mock implementation of the DatabaseManager for use in tests
class MockDatabaseManager {
    private var jobs: [Int: JobApplication] = [:]
    private var attachments: [Int: Attachment] = [:]
    private var nextJobId = 1
    private var nextAttachmentId = 1
    
    init() {
        // Empty initialization
    }
    
    func getAllJobs() -> [JobApplication] {
        return Array(jobs.values)
    }
    
    func getJob(id: Int) -> JobApplication? {
        return jobs[id]
    }
    
    func addJob(companyName: String, jobTitle: String, applicationDate: Date, applicationDeadline: Date, status: String, jobDescription: String, notes: String, contactName: String, contactEmail: String, contactPhone: String) -> Int {
        let jobId = nextJobId
        nextJobId += 1
        
        let job = JobApplication(
            id: jobId,
            companyName: companyName,
            jobTitle: jobTitle,
            applicationDate: applicationDate,
            applicationDeadline: applicationDeadline,
            status: status,
            jobDescription: jobDescription,
            notes: notes,
            contactName: contactName,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            attachments: []
        )
        
        jobs[jobId] = job
        return jobId
    }
    
    func updateJob(id: Int, companyName: String, jobTitle: String, applicationDate: Date, applicationDeadline: Date, status: String, jobDescription: String, notes: String, contactName: String, contactEmail: String, contactPhone: String) -> Bool {
        guard let existingJob = jobs[id] else {
            return false
        }
        
        let updatedJob = JobApplication(
            id: id,
            companyName: companyName,
            jobTitle: jobTitle,
            applicationDate: applicationDate,
            applicationDeadline: applicationDeadline,
            status: status,
            jobDescription: jobDescription,
            notes: notes,
            contactName: contactName,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            attachments: existingJob.attachments
        )
        
        jobs[id] = updatedJob
        return true
    }
    
    func deleteJob(id: Int) -> Bool {
        guard jobs[id] != nil else {
            return false
        }
        
        jobs.removeValue(forKey: id)
        
        // Also delete associated attachments
        let attachmentsToDelete = attachments.filter { $0.value.jobId == id }
        for attachment in attachmentsToDelete {
            attachments.removeValue(forKey: attachment.key)
        }
        
        return true
    }
    
    func getAttachmentsForJob(jobId: Int) -> [Attachment] {
        return attachments.values.filter { $0.jobId == jobId }
    }
    
    func addAttachment(jobId: Int, filePath: String) -> Int {
        guard jobs[jobId] != nil else {
            return -1
        }
        
        let attachmentId = nextAttachmentId
        nextAttachmentId += 1
        
        // Extract filename from path
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        
        let attachment = Attachment(
            id: attachmentId,
            jobId: jobId,
            fileName: fileName,
            filePath: filePath,
            dateAdded: Date()
        )
        
        attachments[attachmentId] = attachment
        
        // Update the job's attachments list
        if var job = jobs[jobId] {
            job.attachments.append(attachment)
            jobs[jobId] = job
        }
        
        return attachmentId
    }
    
    func deleteAttachment(id: Int) -> Bool {
        guard let attachment = attachments[id] else {
            return false
        }
        
        attachments.removeValue(forKey: id)
        
        // Update the job's attachments list
        if var job = jobs[attachment.jobId] {
            job.attachments.removeAll { $0.id == id }
            jobs[attachment.jobId] = job
        }
        
        return true
    }
    
    func searchJobs(query: String) -> [JobApplication] {
        let lowercaseQuery = query.lowercased()
        return jobs.values.filter { job in
            job.companyName.lowercased().contains(lowercaseQuery) ||
            job.jobTitle.lowercased().contains(lowercaseQuery) ||
            job.notes.lowercased().contains(lowercaseQuery)
        }
    }
    
    func filterJobsByStatus(status: String) -> [JobApplication] {
        return jobs.values.filter { $0.status == status }
    }
    
    func filterJobsByDateRange(startDate: Date, endDate: Date, dateField: String) -> [JobApplication] {
        return jobs.values.filter { job in
            let date = dateField == "applicationDate" ? job.applicationDate : job.applicationDeadline
            return date >= startDate && date <= endDate
        }
    }
} 