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
    private var applicationDatePicker: NSDatePicker!
    private var deadlineDatePicker: NSDatePicker!
    private var statusPopUpButton: NSPopUpButton!
    private var jobDescriptionTextView: NSTextView!
    private var contactNameTextField: NSTextField!
    private var contactEmailTextField: NSTextField!
    private var contactPhoneTextField: NSTextField!
    private var saveButton: NSButton!
    private var editModeCheckbox: NSButton! // New checkbox for edit mode
    
    // Edit mode flag
    private var isEditMode: Bool = false
    
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
     * This method creates and configures all the UI elements to match the dark-themed UI shown in the screenshot.
     */
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.darkGray.cgColor
        
        // Increase overall UI size - make the content width larger
        let contentWidth: CGFloat = bounds.width - 40 // 20px padding on each side
        let mainColumn = NSView(frame: NSRect(x: 20, y: 20, width: contentWidth, height: bounds.height - 40))
        mainColumn.wantsLayer = true
        
        // Starting Y position (from top) - moved higher to accommodate larger UI
        var currentY: CGFloat = bounds.height - 120
        let labelWidth: CGFloat = 180
        let fieldWidth: CGFloat = 350
        let fieldHeight: CGFloat = 30
        let verticalSpacing: CGFloat = 40
        
        // Edit Mode Checkbox
        editModeCheckbox = NSButton(checkboxWithTitle: "Enable Editing", target: self, action: #selector(toggleEditMode))
        editModeCheckbox.frame = NSRect(x: contentWidth - 150, y: bounds.height - 70, width: 150, height: 30)
        editModeCheckbox.state = .off
        mainColumn.addSubview(editModeCheckbox)
        
        // Company Name
        let companyLabel = NSTextField(labelWithString: "Company:")
        companyLabel.frame = NSRect(x: 0, y: currentY, width: labelWidth, height: 24)
        companyLabel.textColor = NSColor.white
        companyLabel.font = NSFont.systemFont(ofSize: 16)
        mainColumn.addSubview(companyLabel)
        
        companyNameTextField = NSTextField(frame: NSRect(x: labelWidth, y: currentY, width: fieldWidth, height: fieldHeight))
        companyNameTextField.font = NSFont.systemFont(ofSize: 16)
        companyNameTextField.isEditable = false
        mainColumn.addSubview(companyNameTextField)
        
        currentY -= verticalSpacing
        
        // Application Date
        let appDateLabel = NSTextField(labelWithString: "Application Date:")
        appDateLabel.frame = NSRect(x: 0, y: currentY, width: labelWidth, height: 24)
        appDateLabel.textColor = NSColor.white
        appDateLabel.font = NSFont.systemFont(ofSize: 16)
        mainColumn.addSubview(appDateLabel)
        
        applicationDatePicker = NSDatePicker(frame: NSRect(x: labelWidth, y: currentY, width: fieldWidth, height: fieldHeight))
        applicationDatePicker.datePickerStyle = .textField
        applicationDatePicker.datePickerElements = .yearMonthDay
        applicationDatePicker.font = NSFont.systemFont(ofSize: 16)
        applicationDatePicker.isEnabled = false
        mainColumn.addSubview(applicationDatePicker)
        
        currentY -= verticalSpacing
        
        // Deadline Date
        let deadlineLabel = NSTextField(labelWithString: "Deadline Date:")
        deadlineLabel.frame = NSRect(x: 0, y: currentY, width: labelWidth, height: 24)
        deadlineLabel.textColor = NSColor.white
        deadlineLabel.font = NSFont.systemFont(ofSize: 16)
        mainColumn.addSubview(deadlineLabel)
        
        deadlineDatePicker = NSDatePicker(frame: NSRect(x: labelWidth, y: currentY, width: fieldWidth, height: fieldHeight))
        deadlineDatePicker.datePickerStyle = .textField
        deadlineDatePicker.datePickerElements = .yearMonthDay
        deadlineDatePicker.font = NSFont.systemFont(ofSize: 16)
        deadlineDatePicker.isEnabled = false
        mainColumn.addSubview(deadlineDatePicker)
        
        currentY -= verticalSpacing
        
        // Status
        let statusLabel = NSTextField(labelWithString: "Status:")
        statusLabel.frame = NSRect(x: 0, y: currentY, width: labelWidth, height: 24)
        statusLabel.textColor = NSColor.white
        statusLabel.font = NSFont.systemFont(ofSize: 16)
        mainColumn.addSubview(statusLabel)
        
        statusPopUpButton = NSPopUpButton(frame: NSRect(x: labelWidth, y: currentY, width: fieldWidth, height: fieldHeight))
        statusPopUpButton.addItems(withTitles: ["Applied", "Interviewing", "Offer", "Rejected", "Accepted"])
        statusPopUpButton.font = NSFont.systemFont(ofSize: 16)
        statusPopUpButton.isEnabled = false
        mainColumn.addSubview(statusPopUpButton)
        
        currentY -= verticalSpacing
        
        // Contact Name
        let nameLabel = NSTextField(labelWithString: "Name:")
        nameLabel.frame = NSRect(x: 0, y: currentY, width: labelWidth, height: 24)
        nameLabel.textColor = NSColor.white
        nameLabel.font = NSFont.systemFont(ofSize: 16)
        mainColumn.addSubview(nameLabel)
        
        contactNameTextField = NSTextField(frame: NSRect(x: labelWidth, y: currentY, width: fieldWidth, height: fieldHeight))
        contactNameTextField.font = NSFont.systemFont(ofSize: 16)
        contactNameTextField.isEditable = false
        mainColumn.addSubview(contactNameTextField)
        
        currentY -= verticalSpacing
        
        // Contact Email
        let emailLabel = NSTextField(labelWithString: "Email:")
        emailLabel.frame = NSRect(x: 0, y: currentY, width: labelWidth, height: 24)
        emailLabel.textColor = NSColor.white
        emailLabel.font = NSFont.systemFont(ofSize: 16)
        mainColumn.addSubview(emailLabel)
        
        contactEmailTextField = NSTextField(frame: NSRect(x: labelWidth, y: currentY, width: fieldWidth, height: fieldHeight))
        contactEmailTextField.font = NSFont.systemFont(ofSize: 16)
        contactEmailTextField.isEditable = false
        mainColumn.addSubview(contactEmailTextField)
        
        currentY -= verticalSpacing
        
        // Contact Phone
        let phoneLabel = NSTextField(labelWithString: "Phone:")
        phoneLabel.frame = NSRect(x: 0, y: currentY, width: labelWidth, height: 24)
        phoneLabel.textColor = NSColor.white
        phoneLabel.font = NSFont.systemFont(ofSize: 16)
        mainColumn.addSubview(phoneLabel)
        
        contactPhoneTextField = NSTextField(frame: NSRect(x: labelWidth, y: currentY, width: fieldWidth, height: fieldHeight))
        contactPhoneTextField.font = NSFont.systemFont(ofSize: 16)
        contactPhoneTextField.isEditable = false
        mainColumn.addSubview(contactPhoneTextField)
        
        currentY -= verticalSpacing
        
        // Job Description
        let jobDescLabel = NSTextField(labelWithString: "Job Description:")
        jobDescLabel.frame = NSRect(x: 0, y: currentY, width: labelWidth, height: 24)
        jobDescLabel.textColor = NSColor.white
        jobDescLabel.font = NSFont.systemFont(ofSize: 16)
        mainColumn.addSubview(jobDescLabel)
        
        currentY -= 20 // Add a smaller gap for the text view
        
        let scrollViewHeight: CGFloat = 250 // Increased height for description box
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: currentY - scrollViewHeight, width: contentWidth, height: scrollViewHeight))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        
        jobDescriptionTextView = NSTextView(frame: NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height))
        jobDescriptionTextView.font = NSFont.systemFont(ofSize: 14)
        jobDescriptionTextView.isEditable = false
        jobDescriptionTextView.textContainerInset = NSSize(width: 5, height: 5)
        jobDescriptionTextView.backgroundColor = NSColor.darkGray.withAlphaComponent(0.8)
        jobDescriptionTextView.textColor = NSColor.white
        
        scrollView.documentView = jobDescriptionTextView
        mainColumn.addSubview(scrollView)
        
        // Save Button - moved to bottom right
        saveButton = NSButton(frame: NSRect(x: contentWidth - 120, y: 20, width: 100, height: 34))
        saveButton.title = "Save"
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveChanges)
        saveButton.isEnabled = false // Disabled by default since we're in readonly mode
        mainColumn.addSubview(saveButton)
        
        // Add main column to view
        addSubview(mainColumn)
        
        // Start with fields filled and readonly
        populateDefaultValues()
    }
    
    /**
     * Populates the form with default values.
     */
    private func populateDefaultValues() {
        companyNameTextField.stringValue = "test"
        applicationDatePicker.dateValue = Date()
        
        // Set deadline to 1 week from now
        deadlineDatePicker.dateValue = Date().addingTimeInterval(60 * 60 * 24 * 7)
        
        statusPopUpButton.selectItem(at: 0) // Applied
        jobDescriptionTextView.string = "Enter the job description here. Include details about responsibilities, requirements, and any other relevant information about the position."
        contactNameTextField.stringValue = "test"
        contactEmailTextField.stringValue = "test"
        contactPhoneTextField.stringValue = "3333333333"
    }
    
    /**
     * Toggles edit mode on/off based on the checkbox state.
     */
    @objc private func toggleEditMode(_ sender: NSButton) {
        isEditMode = (sender.state == .on)
        setFieldsEnabled(isEditMode)
    }
    
    /**
     * Enables or disables all input fields in the view.
     *
     * - Parameter enabled: Whether the fields should be enabled
     */
    private func setFieldsEnabled(_ enabled: Bool) {
        companyNameTextField?.isEditable = enabled
        applicationDatePicker?.isEnabled = enabled
        deadlineDatePicker?.isEnabled = enabled
        statusPopUpButton?.isEnabled = enabled
        jobDescriptionTextView?.isEditable = enabled
        contactNameTextField?.isEditable = enabled
        contactEmailTextField?.isEditable = enabled
        contactPhoneTextField?.isEditable = enabled
        saveButton?.isEnabled = enabled
    }
    
    /**
     * Displays the specified job application in the detail view.
     *
     * - Parameter jobApplication: The job application to display, or nil to clear the view
     */
    func display(jobApplication: JobApplication?) {
        currentJob = jobApplication
        
        if let job = jobApplication {
            // App is selected, show its information
            companyNameTextField.stringValue = job.companyName
            applicationDatePicker.dateValue = job.applicationDate
            deadlineDatePicker.dateValue = job.applicationDeadline
            
            // Set the status
            if let statusIndex = statusPopUpButton.itemTitles.firstIndex(of: job.status) {
                statusPopUpButton.selectItem(at: statusIndex)
            } else {
                statusPopUpButton.selectItem(at: 0) // Default to first item
            }
            
            // Set text fields
            jobDescriptionTextView.string = job.jobDescription
            contactNameTextField.stringValue = job.contactName
            contactEmailTextField.stringValue = job.contactEmail
            contactPhoneTextField.stringValue = job.contactPhone
            
            // Keep fields disabled by default (unless edit mode is on)
            setFieldsEnabled(isEditMode)
        } else {
            // No job selected, use default values
            populateDefaultValues()
            setFieldsEnabled(isEditMode)
        }
    }
    
    /**
     * Saves the changes made to the job application.
     */
    @objc private func saveChanges() {
        guard var updatedJob = currentJob else { return }
        
        // Update job with values from fields
        updatedJob.companyName = companyNameTextField.stringValue
        updatedJob.applicationDate = applicationDatePicker.dateValue
        updatedJob.applicationDeadline = deadlineDatePicker.dateValue
        updatedJob.status = statusPopUpButton.titleOfSelectedItem ?? "Applied"
        updatedJob.jobDescription = jobDescriptionTextView.string
        updatedJob.contactName = contactNameTextField.stringValue
        updatedJob.contactEmail = contactEmailTextField.stringValue
        updatedJob.contactPhone = contactPhoneTextField.stringValue
        
        // Notify delegate about the update
        delegate?.jobDetailViewDidUpdate(updatedJob)
        
        // Disable edit mode after saving
        editModeCheckbox.state = .off
        isEditMode = false
        setFieldsEnabled(false)
    }
} 