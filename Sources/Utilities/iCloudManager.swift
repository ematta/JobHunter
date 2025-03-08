import Foundation

/**
 * Manages iCloud file synchronization for the application.
 *
 * This class provides functionality to store and retrieve files using iCloud storage,
 * with local fallback when iCloud is not available.
 */
class CloudManager: ObservableObject {
    private let fileManager = FileManager.default
    private let ubiquityContainerIdentifier: String? = nil // Default iCloud container
    
    /**
     * The documents directory in iCloud or locally if iCloud is not available.
     *
     * This computed property determines the appropriate directory for storing files,
     * creating it if it doesn't exist.
     *
     * - Returns: The URL of the documents directory
     * - Throws: An error if the directory cannot be accessed or created
     */
    private var documentsDirectory: URL {
        get throws {
            if let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier)?.appendingPathComponent("Documents") {
                // Create the directory if it doesn't exist
                if !fileManager.fileExists(atPath: iCloudURL.path) {
                    try fileManager.createDirectory(at: iCloudURL, withIntermediateDirectories: true, attributes: nil)
                }
                return iCloudURL
            } else {
                // Fallback to local documents directory if iCloud is not available
                return try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            }
        }
    }
    
    /**
     * Indicates whether iCloud is available for the application.
     *
     * - Returns: A boolean value indicating if iCloud is available
     */
    var isICloudAvailable: Bool {
        return fileManager.url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier) != nil
    }
    
    /**
     * Copies a file to the documents directory in a job-specific folder.
     *
     * This method creates a directory for the specified job if it doesn't exist,
     * then copies the file, ensuring a unique filename to avoid overwriting existing files.
     *
     * - Parameters:
     *   - fileURL: The URL of the file to copy
     *   - jobId: The ID of the job application to associate the file with
     * - Returns: The URL of the copied file
     * - Throws: An error if the file operation fails
     */
    func copyFileToDocuments(_ fileURL: URL, forJobId jobId: Int) throws -> URL {
        // Create a directory for the job if it doesn't exist
        let jobDirectory = try getJobDirectory(jobId)
        
        // Create a unique filename to avoid overwriting existing files
        let filename = fileURL.lastPathComponent
        let destinationURL = jobDirectory.appendingPathComponent(filename)
        
        // If the file already exists, create a unique name
        if fileManager.fileExists(atPath: destinationURL.path) {
            let fileExtension = fileURL.pathExtension
            let baseName = filename.replacingOccurrences(of: ".\(fileExtension)", with: "")
            let timestamp = Int(Date().timeIntervalSince1970)
            let newFilename = "\(baseName)_\(timestamp).\(fileExtension)"
            let newDestinationURL = jobDirectory.appendingPathComponent(newFilename)
            
            try fileManager.copyItem(at: fileURL, to: newDestinationURL)
            return newDestinationURL
        } else {
            try fileManager.copyItem(at: fileURL, to: destinationURL)
            return destinationURL
        }
    }
    
    /**
     * Gets the directory associated with a specific job.
     *
     * This method returns the directory for storing files related to a specific job,
     * creating it if it doesn't exist.
     *
     * - Parameter jobId: The ID of the job application
     * - Returns: The URL of the job directory
     * - Throws: An error if the directory cannot be accessed or created
     */
    func getJobDirectory(_ jobId: Int) throws -> URL {
        let documentsDir = try documentsDirectory
        let jobDirectory = documentsDir.appendingPathComponent("Job_\(jobId)")
        
        if !fileManager.fileExists(atPath: jobDirectory.path) {
            try fileManager.createDirectory(at: jobDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return jobDirectory
    }
    
    /**
     * Deletes a file at the specified URL.
     *
     * - Parameter fileURL: The URL of the file to delete
     * - Throws: An error if the file cannot be deleted
     */
    func deleteFile(at fileURL: URL) throws {
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    /**
     * Gets all attachment files for a specific job.
     *
     * - Parameter jobId: The ID of the job application
     * - Returns: An array of URLs for all files in the job directory
     * - Throws: An error if the files cannot be accessed
     */
    func getAttachmentsForJob(_ jobId: Int) throws -> [URL] {
        let jobDirectory = try getJobDirectory(jobId)
        
        let fileURLs = try fileManager.contentsOfDirectory(at: jobDirectory, includingPropertiesForKeys: nil)
        return fileURLs
    }
    
    /**
     * Exports all attachments for a job to a specified directory.
     *
     * - Parameters:
     *   - jobId: The ID of the job application
     *   - exportDirectory: The directory to export the attachments to
     * - Returns: An array of URLs for the exported files
     * - Throws: An error if the files cannot be exported
     */
    func exportAttachmentsForJob(_ jobId: Int, to exportDirectory: URL) throws -> [URL] {
        let jobDirectory = try getJobDirectory(jobId)
        
        let fileURLs = try fileManager.contentsOfDirectory(at: jobDirectory, includingPropertiesForKeys: nil)
        
        var exportedURLs: [URL] = []
        
        for fileURL in fileURLs {
            let destinationURL = exportDirectory.appendingPathComponent(fileURL.lastPathComponent)
            try fileManager.copyItem(at: fileURL, to: destinationURL)
            exportedURLs.append(destinationURL)
        }
        
        return exportedURLs
    }
    
    // Set up iCloud document storage
    func setupiCloudDocumentStorage() {
        if isICloudAvailable {
            print("iCloud document storage is available")
            
            // Start monitoring iCloud file changes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleiCloudDocumentChange(_:)),
                name: NSNotification.Name.NSMetadataQueryDidUpdate,
                object: nil
            )
        } else {
            print("iCloud document storage is not available")
        }
    }
    
    @objc private func handleiCloudDocumentChange(_ notification: Notification) {
        if let url = notification.userInfo?["NSMetadataQueryResultKey"] as? URL {
            print("iCloud file changed: \(url.path)")
            
            // Handle file changes here
            // For example, you might want to update the database or UI when a file is updated
        }
    }
} 