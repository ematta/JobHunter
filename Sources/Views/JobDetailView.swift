import AppKit
import Foundation
import UniformTypeIdentifiers

/**
 * Protocol for handling updates to job applications in the detail view.
 */
protocol JobDetailViewDelegate: AnyObject {
    /**
     * Called when a job application has been updated in the detail view.
     *
     * - Parameter jobApplication: The updated job application
     */
    func jobDetailViewDidUpdate(_ jobApplication: JobApplication)
}

/**
 * A view that displays and allows editing of job application details.
 *
 * This view includes fields for all job application properties and handles
 * the display, editing, and attachment management for a job application.
 */
class JobDetailView: NSView {
    private let databaseManager: DatabaseManager
    private let iCloudManager: iCloudManager
    
    weak var delegate: JobDetailViewDelegate?
    private var currentJob: JobApplication?
    
    // UI Components
    private var companyNameTextField: NSTextField!
    private var jobTitleTextField: NSTextField!
    private var applicationDatePicker: NSDatePicker!
    private var deadlineDatePicker: NSDatePicker!
    private var statusPopUpButton: NSPopUpButton!
    private var jobDescriptionTextView: NSTextView!
    private var notesTextView: NSTextView!
    private var contactNameTextField: NSTextField!
    private var contactEmailTextField: NSTextField!
    private var contactPhoneTextField: NSTextField!
    private var attachmentsTableView: NSTableView!
    private var addAttachmentButton: NSButton!
    private var removeAttachmentButton: NSButton!
    
    /**
     * Initializes a new JobDetailView with the specified frame and dependencies.
     *
     * - Parameters:
     *   - frame: The frame rectangle for the view
     *   - databaseManager: The database manager for persistence operations
     *   - iCloudManager: The iCloud manager for file operations
     */
    init(frame: NSRect, databaseManager: DatabaseManager, iCloudManager: iCloudManager) {
        self.databaseManager = databaseManager
        self.iCloudManager = iCloudManager
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     * Sets up the user interface components for the job detail view.
     *
     * This method creates and configures all the UI elements including text fields,
     * date pickers, dropdown menus, text views, and buttons.
     */
    private func setupUI() {
        wantsLayer = true
        
        // Header
        let headerView = NSView(frame: NSRect(x: 0, y: bounds.height - 80, width: bounds.width, height: 80))
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Company and Job Title
        let headerTitleView = NSView(frame: NSRect(x: 20, y: 0, width: headerView.bounds.width - 40, height: headerView.bounds.height))
        
        let companyNameLabel = NSTextField(labelWithString: "Company Name:")
        companyNameLabel.frame = NSRect(x: 0, y: 45, width: 150, height: 20)
        headerTitleView.addSubview(companyNameLabel)
        
        companyNameTextField = NSTextField(frame: NSRect(x: 150, y: 45, width: headerTitleView.bounds.width - 150, height: 24))
        headerTitleView.addSubview(companyNameTextField)
        
        let jobTitleLabel = NSTextField(labelWithString: "Job Title:")
        jobTitleLabel.frame = NSRect(x: 0, y: 15, width: 150, height: 20)
        headerTitleView.addSubview(jobTitleLabel)
        
        jobTitleTextField = NSTextField(frame: NSRect(x: 150, y: 15, width: headerTitleView.bounds.width - 150, height: 24))
        headerTitleView.addSubview(jobTitleTextField)
        
        headerView.addSubview(headerTitleView)
        addSubview(headerView)
        
        // Main Content (using Tab View)
        let tabView = NSTabView(frame: NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 80))
        
        // Details Tab
        let detailsTab = NSTabViewItem(identifier: "details")
        detailsTab.label = "Details"
        detailsTab.view = createDetailsView(frame: NSRect(x: 0, y: 0, width: tabView.bounds.width, height: tabView.bounds.height - 20))
        tabView.addTabViewItem(detailsTab)
        
        // Attachments Tab
        let attachmentsTab = NSTabViewItem(identifier: "attachments")
        attachmentsTab.label = "Attachments"
        attachmentsTab.view = createAttachmentsView(frame: NSRect(x: 0, y: 0, width: tabView.bounds.width, height: tabView.bounds.height - 20))
        tabView.addTabViewItem(attachmentsTab)
        
        // Notes Tab
        let notesTab = NSTabViewItem(identifier: "notes")
        notesTab.label = "Notes"
        notesTab.view = createNotesView(frame: NSRect(x: 0, y: 0, width: tabView.bounds.width, height: tabView.bounds.height - 20))
        tabView.addTabViewItem(notesTab)
        
        addSubview(tabView)
        
        // Add Save Button
        let saveButton = NSButton(title: "Save Changes", target: self, action: #selector(saveChanges(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.frame = NSRect(x: bounds.width - 150, y: 10, width: 120, height: 32)
        addSubview(saveButton)
    }
    
    private func createDetailsView(frame: NSRect) -> NSView {
        let view = NSView(frame: frame)
        
        // Application Date
        let applicationDateLabel = NSTextField(labelWithString: "Application Date:")
        applicationDateLabel.frame = NSRect(x: 20, y: frame.height - 40, width: 150, height: 20)
        view.addSubview(applicationDateLabel)
        
        applicationDatePicker = NSDatePicker(frame: NSRect(x: 180, y: frame.height - 40, width: 200, height: 24))
        applicationDatePicker.datePickerStyle = .textField
        applicationDatePicker.datePickerElements = [.yearMonth, .yearMonthDay]
        view.addSubview(applicationDatePicker)
        
        // Deadline Date
        let deadlineDateLabel = NSTextField(labelWithString: "Deadline Date:")
        deadlineDateLabel.frame = NSRect(x: 20, y: frame.height - 80, width: 150, height: 20)
        view.addSubview(deadlineDateLabel)
        
        deadlineDatePicker = NSDatePicker(frame: NSRect(x: 180, y: frame.height - 80, width: 200, height: 24))
        deadlineDatePicker.datePickerStyle = .textField
        deadlineDatePicker.datePickerElements = [.yearMonth, .yearMonthDay]
        view.addSubview(deadlineDatePicker)
        
        // Status
        let statusLabel = NSTextField(labelWithString: "Status:")
        statusLabel.frame = NSRect(x: 20, y: frame.height - 120, width: 150, height: 20)
        view.addSubview(statusLabel)
        
        statusPopUpButton = NSPopUpButton(frame: NSRect(x: 180, y: frame.height - 120, width: 200, height: 24))
        statusPopUpButton.addItems(withTitles: ["Applied", "Interviewing", "Offered", "Rejected"])
        view.addSubview(statusPopUpButton)
        
        // Contact Information
        let contactInfoLabel = NSTextField(labelWithString: "Contact Information")
        contactInfoLabel.font = NSFont.boldSystemFont(ofSize: 14)
        contactInfoLabel.frame = NSRect(x: 20, y: frame.height - 160, width: 200, height: 20)
        view.addSubview(contactInfoLabel)
        
        // Contact Name
        let contactNameLabel = NSTextField(labelWithString: "Name:")
        contactNameLabel.frame = NSRect(x: 40, y: frame.height - 190, width: 100, height: 20)
        view.addSubview(contactNameLabel)
        
        contactNameTextField = NSTextField(frame: NSRect(x: 150, y: frame.height - 190, width: 250, height: 24))
        view.addSubview(contactNameTextField)
        
        // Contact Email
        let contactEmailLabel = NSTextField(labelWithString: "Email:")
        contactEmailLabel.frame = NSRect(x: 40, y: frame.height - 220, width: 100, height: 20)
        view.addSubview(contactEmailLabel)
        
        contactEmailTextField = NSTextField(frame: NSRect(x: 150, y: frame.height - 220, width: 250, height: 24))
        view.addSubview(contactEmailTextField)
        
        // Contact Phone
        let contactPhoneLabel = NSTextField(labelWithString: "Phone:")
        contactPhoneLabel.frame = NSRect(x: 40, y: frame.height - 250, width: 100, height: 20)
        view.addSubview(contactPhoneLabel)
        
        contactPhoneTextField = NSTextField(frame: NSRect(x: 150, y: frame.height - 250, width: 250, height: 24))
        view.addSubview(contactPhoneTextField)
        
        // Job Description
        let jobDescriptionLabel = NSTextField(labelWithString: "Job Description:")
        jobDescriptionLabel.frame = NSRect(x: 20, y: frame.height - 290, width: 150, height: 20)
        view.addSubview(jobDescriptionLabel)
        
        let jobDescriptionScrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: frame.width - 40, height: frame.height - 330))
        jobDescriptionScrollView.hasVerticalScroller = true
        jobDescriptionScrollView.borderType = .bezelBorder
        
        jobDescriptionTextView = NSTextView(frame: NSRect(x: 0, y: 0, width: jobDescriptionScrollView.contentSize.width, height: jobDescriptionScrollView.contentSize.height))
        jobDescriptionTextView.font = NSFont.systemFont(ofSize: 13)
        jobDescriptionTextView.autoresizingMask = [.width, .height]
        jobDescriptionTextView.isEditable = true
        jobDescriptionTextView.isSelectable = true
        
        jobDescriptionScrollView.documentView = jobDescriptionTextView
        view.addSubview(jobDescriptionScrollView)
        
        return view
    }
    
    private func createAttachmentsView(frame: NSRect) -> NSView {
        let view = NSView(frame: frame)
        
        // Instructions Label
        let instructionsLabel = NSTextField(labelWithString: "Attach resumes, cover letters, and other documents related to this job application.")
        instructionsLabel.frame = NSRect(x: 20, y: frame.height - 40, width: frame.width - 40, height: 20)
        view.addSubview(instructionsLabel)
        
        // Create the table view
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: frame.width - 40, height: frame.height - 120))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        
        attachmentsTableView = NSTableView(frame: NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height))
        
        // Create filename column
        let filenameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("filenameColumn"))
        filenameColumn.title = "Filename"
        filenameColumn.width = scrollView.contentSize.width - 100
        attachmentsTableView.addTableColumn(filenameColumn)
        
        // Create type column
        let typeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("typeColumn"))
        typeColumn.title = "Type"
        typeColumn.width = 80
        attachmentsTableView.addTableColumn(typeColumn)
        
        attachmentsTableView.delegate = self
        attachmentsTableView.dataSource = self
        
        scrollView.documentView = attachmentsTableView
        view.addSubview(scrollView)
        
        // Buttons for attachments
        addAttachmentButton = NSButton(title: "Add Document", target: self, action: #selector(addAttachment(_:)))
        addAttachmentButton.bezelStyle = .rounded
        addAttachmentButton.frame = NSRect(x: 20, y: 20, width: 120, height: 32)
        view.addSubview(addAttachmentButton)
        
        removeAttachmentButton = NSButton(title: "Remove", target: self, action: #selector(removeAttachment(_:)))
        removeAttachmentButton.bezelStyle = .rounded
        removeAttachmentButton.frame = NSRect(x: 150, y: 20, width: 80, height: 32)
        view.addSubview(removeAttachmentButton)
        
        let openButton = NSButton(title: "Open", target: self, action: #selector(openAttachment(_:)))
        openButton.bezelStyle = .rounded
        openButton.frame = NSRect(x: 240, y: 20, width: 80, height: 32)
        view.addSubview(openButton)
        
        return view
    }
    
    private func createNotesView(frame: NSRect) -> NSView {
        let view = NSView(frame: frame)
        
        // Notes
        let notesLabel = NSTextField(labelWithString: "Notes:")
        notesLabel.frame = NSRect(x: 20, y: frame.height - 40, width: 150, height: 20)
        view.addSubview(notesLabel)
        
        let notesScrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: frame.width - 40, height: frame.height - 80))
        notesScrollView.hasVerticalScroller = true
        notesScrollView.borderType = .bezelBorder
        
        notesTextView = NSTextView(frame: NSRect(x: 0, y: 0, width: notesScrollView.contentSize.width, height: notesScrollView.contentSize.height))
        notesTextView.font = NSFont.systemFont(ofSize: 13)
        notesTextView.autoresizingMask = [.width, .height]
        notesTextView.isEditable = true
        notesTextView.isSelectable = true
        
        notesScrollView.documentView = notesTextView
        view.addSubview(notesScrollView)
        
        return view
    }
    
    // MARK: - Public Methods
    
    func displayJobApplication(_ jobApplication: JobApplication) {
        currentJob = jobApplication
        
        // Update UI with job data
        companyNameTextField.stringValue = jobApplication.companyName
        jobTitleTextField.stringValue = jobApplication.jobTitle
        applicationDatePicker.dateValue = Date() // Set to current date
        deadlineDatePicker.dateValue = jobApplication.applicationDeadline
        
        // Set status
        let index = statusPopUpButton.indexOfItem(withTitle: jobApplication.status)
        if index != -1 {
            statusPopUpButton.selectItem(at: index)
        } else {
            statusPopUpButton.selectItem(at: 0) // Default to "Applied"
        }
        
        // Set job description with default if empty
        if jobApplication.jobDescription.isEmpty {
            jobDescriptionTextView.string = "Enter the job description here. Include details about responsibilities, requirements, and any other relevant information about the position."
        } else {
            jobDescriptionTextView.string = jobApplication.jobDescription
        }
        
        notesTextView.string = jobApplication.notes
        contactNameTextField.stringValue = jobApplication.contactName
        contactEmailTextField.stringValue = jobApplication.contactEmail
        contactPhoneTextField.stringValue = jobApplication.contactPhone
        
        // Reload attachments
        attachmentsTableView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func saveChanges(_ sender: NSButton) {
        guard var updatedJob = currentJob else { return }
        
        updatedJob.companyName = companyNameTextField.stringValue
        updatedJob.jobTitle = jobTitleTextField.stringValue
        updatedJob.applicationDate = applicationDatePicker.dateValue
        updatedJob.applicationDeadline = deadlineDatePicker.dateValue
        updatedJob.status = statusPopUpButton.titleOfSelectedItem ?? "Applied"
        updatedJob.jobDescription = jobDescriptionTextView.string
        updatedJob.notes = notesTextView.string
        updatedJob.contactName = contactNameTextField.stringValue
        updatedJob.contactEmail = contactEmailTextField.stringValue
        updatedJob.contactPhone = contactPhoneTextField.stringValue
        
        delegate?.jobDetailViewDidUpdate(updatedJob)
    }
    
    @objc private func addAttachment(_ sender: NSButton) {
        guard let currentJob = currentJob else { return }
        
        // Create an open panel
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Document"
        
        // Use UTType for content types
        var contentTypes: [UTType] = [
            .pdf,
            .plainText,
            .rtf
        ]
        
        // Add Microsoft Word document types
        if let wordType = UTType(filenameExtension: "doc") {
            contentTypes.append(wordType)
        }
        
        if let docxType = UTType(filenameExtension: "docx") {
            contentTypes.append(docxType)
        }
        
        openPanel.allowedContentTypes = contentTypes
        openPanel.allowsMultipleSelection = false
        
        openPanel.beginSheetModal(for: window!) { response in
            if response == .OK, let url = openPanel.url {
                do {
                    // Copy the file to the application's documents directory
                    let documentURL = try self.iCloudManager.copyFileToDocuments(url, forJobId: currentJob.id)
                    
                    // Create a new attachment
                    let attachment = Attachment(
                        id: -1, // Database will assign a proper ID
                        jobId: currentJob.id,
                        fileName: url.lastPathComponent,
                        filePath: documentURL.path,
                        dateAdded: Date()
                    )
                    
                    // Save the attachment to the database
                    let _ = try self.databaseManager.addAttachment(attachment)
                    
                    // Reload the job to get the updated attachments
                    if let updatedJob = try self.databaseManager.getJobApplication(currentJob.id) {
                        self.displayJobApplication(updatedJob)
                    }
                } catch {
                    print("Failed to add attachment: \(error)")
                    self.showAlert(title: "Error", message: "Failed to add attachment: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func removeAttachment(_ sender: NSButton) {
        guard let currentJob = currentJob else { return }
        let selectedRow = attachmentsTableView.selectedRow
        
        guard selectedRow >= 0, selectedRow < currentJob.attachments.count else {
            showAlert(title: "Error", message: "Please select an attachment to remove")
            return
        }
        
        let attachment = currentJob.attachments[selectedRow]
        
        let alert = NSAlert()
        alert.messageText = "Remove Attachment"
        alert.informativeText = "Are you sure you want to remove the attachment '\(attachment.fileName)'?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        
        alert.beginSheetModal(for: window!) { response in
            if response == .alertFirstButtonReturn {
                do {
                    // Delete the file from the documents directory
                    try self.iCloudManager.deleteFile(at: URL(fileURLWithPath: attachment.filePath))
                    
                    // Delete the attachment from the database
                    try self.databaseManager.deleteAttachment(attachment.id)
                    
                    // Reload the job to get the updated attachments
                    if let updatedJob = try self.databaseManager.getJobApplication(currentJob.id) {
                        self.displayJobApplication(updatedJob)
                    }
                } catch {
                    print("Failed to remove attachment: \(error)")
                    self.showAlert(title: "Error", message: "Failed to remove attachment: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func openAttachment(_ sender: NSButton) {
        guard let currentJob = currentJob else { return }
        let selectedRow = attachmentsTableView.selectedRow
        
        guard selectedRow >= 0, selectedRow < currentJob.attachments.count else {
            showAlert(title: "Error", message: "Please select an attachment to open")
            return
        }
        
        let attachment = currentJob.attachments[selectedRow]
        let fileURL = URL(fileURLWithPath: attachment.filePath)
        
        NSWorkspace.shared.open(fileURL)
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        if let window = window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
}

// MARK: - NSTableViewDelegate & NSTableViewDataSource

extension JobDetailView: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return currentJob?.attachments.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let currentJob = currentJob, row < currentJob.attachments.count else { return nil }
        
        let attachment = currentJob.attachments[row]
        let identifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("")
        
        if let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
            return cell
        }
        
        let cell = NSTableCellView()
        cell.identifier = identifier
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: tableColumn?.width ?? 0, height: 20))
        textField.isEditable = false
        textField.isBordered = false
        textField.drawsBackground = false
        cell.textField = textField
        cell.addSubview(textField)
        
        if identifier.rawValue == "filenameColumn" {
            textField.stringValue = attachment.fileName
        } else if identifier.rawValue == "typeColumn" {
            let fileExtension = URL(fileURLWithPath: attachment.fileName).pathExtension.uppercased()
            textField.stringValue = fileExtension
        }
        
        return cell
    }
} 