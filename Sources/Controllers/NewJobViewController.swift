import AppKit
import Foundation

/**
 * A view controller for creating new job applications.
 *
 * This controller presents a form for the user to input details about a new job application,
 * including company name, job title, dates, and contact information.
 */
class NewJobViewController: NSViewController {
    private let databaseManager: DatabaseManager
    
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
    
    /// Callback for when a job is successfully added
    var onJobAdded: (() -> Void)?
    
    /**
     * Initializes a new job view controller with the specified database manager.
     *
     * - Parameter databaseManager: The database manager for persistence operations
     */
    init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     * Creates and sets up the view.
     */
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 700))
    }
    
    /**
     * Called after the view controller's view has been loaded into memory.
     *
     * Sets up the user interface components.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    /**
     * Sets up the user interface components for the new job form.
     *
     * Creates and configures all the input fields, labels, and buttons needed
     * to input details for a new job application.
     */
    private func setupUI() {
        // Title label
        let titleLabel = NSTextField(labelWithString: "Add New Job Application")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 20, y: view.bounds.height - 50, width: view.bounds.width - 40, height: 30)
        view.addSubview(titleLabel)
        
        // Company Name
        let companyNameLabel = NSTextField(labelWithString: "Company Name:")
        companyNameLabel.frame = NSRect(x: 20, y: view.bounds.height - 100, width: 150, height: 20)
        view.addSubview(companyNameLabel)
        
        companyNameTextField = NSTextField(frame: NSRect(x: 180, y: view.bounds.height - 100, width: view.bounds.width - 200, height: 24))
        view.addSubview(companyNameTextField)
        
        // Job Title
        let jobTitleLabel = NSTextField(labelWithString: "Job Title:")
        jobTitleLabel.frame = NSRect(x: 20, y: view.bounds.height - 140, width: 150, height: 20)
        view.addSubview(jobTitleLabel)
        
        jobTitleTextField = NSTextField(frame: NSRect(x: 180, y: view.bounds.height - 140, width: view.bounds.width - 200, height: 24))
        view.addSubview(jobTitleTextField)
        
        // Application Date
        let applicationDateLabel = NSTextField(labelWithString: "Application Date:")
        applicationDateLabel.frame = NSRect(x: 20, y: view.bounds.height - 180, width: 150, height: 20)
        view.addSubview(applicationDateLabel)
        
        applicationDatePicker = NSDatePicker(frame: NSRect(x: 180, y: view.bounds.height - 180, width: 200, height: 24))
        applicationDatePicker.datePickerStyle = .textField
        applicationDatePicker.datePickerElements = [.yearMonth, .yearMonthDay]
        applicationDatePicker.dateValue = Date()
        view.addSubview(applicationDatePicker)
        
        // Deadline Date
        let deadlineDateLabel = NSTextField(labelWithString: "Deadline Date:")
        deadlineDateLabel.frame = NSRect(x: 20, y: view.bounds.height - 220, width: 150, height: 20)
        view.addSubview(deadlineDateLabel)
        
        deadlineDatePicker = NSDatePicker(frame: NSRect(x: 180, y: view.bounds.height - 220, width: 200, height: 24))
        deadlineDatePicker.datePickerStyle = .textField
        deadlineDatePicker.datePickerElements = [.yearMonth, .yearMonthDay]
        deadlineDatePicker.dateValue = Date().addingTimeInterval(60 * 60 * 24 * 7) // One week from now
        view.addSubview(deadlineDatePicker)
        
        // Status
        let statusLabel = NSTextField(labelWithString: "Status:")
        statusLabel.frame = NSRect(x: 20, y: view.bounds.height - 260, width: 150, height: 20)
        view.addSubview(statusLabel)
        
        statusPopUpButton = NSPopUpButton(frame: NSRect(x: 180, y: view.bounds.height - 260, width: 200, height: 24))
        statusPopUpButton.addItems(withTitles: ["Applied", "Interviewing", "Offered", "Rejected"])
        view.addSubview(statusPopUpButton)
        
        // Job Description
        let jobDescriptionLabel = NSTextField(labelWithString: "Job Description:")
        jobDescriptionLabel.frame = NSRect(x: 20, y: view.bounds.height - 300, width: 150, height: 20)
        view.addSubview(jobDescriptionLabel)
        
        let jobDescriptionScrollView = NSScrollView(frame: NSRect(x: 20, y: view.bounds.height - 400, width: view.bounds.width - 40, height: 80))
        jobDescriptionScrollView.hasVerticalScroller = true
        jobDescriptionScrollView.borderType = .bezelBorder
        
        jobDescriptionTextView = NSTextView(frame: NSRect(x: 0, y: 0, width: jobDescriptionScrollView.contentSize.width, height: jobDescriptionScrollView.contentSize.height))
        jobDescriptionTextView.font = NSFont.systemFont(ofSize: 13)
        jobDescriptionTextView.autoresizingMask = [.width, .height]
        jobDescriptionTextView.isEditable = true
        jobDescriptionTextView.isSelectable = true
        jobDescriptionTextView.string = "Enter the job description here. Include details about responsibilities, requirements, and any other relevant information about the position."
        
        jobDescriptionScrollView.documentView = jobDescriptionTextView
        view.addSubview(jobDescriptionScrollView)
        
        // Notes
        let notesLabel = NSTextField(labelWithString: "Notes:")
        notesLabel.frame = NSRect(x: 20, y: view.bounds.height - 420, width: 150, height: 20)
        view.addSubview(notesLabel)
        
        let notesScrollView = NSScrollView(frame: NSRect(x: 20, y: view.bounds.height - 520, width: view.bounds.width - 40, height: 80))
        notesScrollView.hasVerticalScroller = true
        notesScrollView.borderType = .bezelBorder
        
        notesTextView = NSTextView(frame: NSRect(x: 0, y: 0, width: notesScrollView.contentSize.width, height: notesScrollView.contentSize.height))
        notesTextView.font = NSFont.systemFont(ofSize: 13)
        notesTextView.autoresizingMask = [.width, .height]
        notesTextView.isEditable = true
        notesTextView.isSelectable = true
        
        notesScrollView.documentView = notesTextView
        view.addSubview(notesScrollView)
        
        // Contact Information
        let contactInfoLabel = NSTextField(labelWithString: "Contact Information")
        contactInfoLabel.font = NSFont.boldSystemFont(ofSize: 14)
        contactInfoLabel.frame = NSRect(x: 20, y: view.bounds.height - 550, width: 200, height: 20)
        view.addSubview(contactInfoLabel)
        
        // Contact Name
        let contactNameLabel = NSTextField(labelWithString: "Name:")
        contactNameLabel.frame = NSRect(x: 20, y: view.bounds.height - 580, width: 150, height: 20)
        view.addSubview(contactNameLabel)
        
        contactNameTextField = NSTextField(frame: NSRect(x: 180, y: view.bounds.height - 580, width: view.bounds.width - 200, height: 24))
        view.addSubview(contactNameTextField)
        
        // Contact Email
        let contactEmailLabel = NSTextField(labelWithString: "Email:")
        contactEmailLabel.frame = NSRect(x: 20, y: view.bounds.height - 610, width: 150, height: 20)
        view.addSubview(contactEmailLabel)
        
        contactEmailTextField = NSTextField(frame: NSRect(x: 180, y: view.bounds.height - 610, width: view.bounds.width - 200, height: 24))
        view.addSubview(contactEmailTextField)
        
        // Contact Phone
        let contactPhoneLabel = NSTextField(labelWithString: "Phone:")
        contactPhoneLabel.frame = NSRect(x: 20, y: view.bounds.height - 640, width: 150, height: 20)
        view.addSubview(contactPhoneLabel)
        
        contactPhoneTextField = NSTextField(frame: NSRect(x: 180, y: view.bounds.height - 640, width: view.bounds.width - 200, height: 24))
        view.addSubview(contactPhoneTextField)
        
        // Buttons
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelButtonClicked(_:)))
        cancelButton.bezelStyle = .rounded
        cancelButton.frame = NSRect(x: view.bounds.width - 200, y: 20, width: 80, height: 32)
        view.addSubview(cancelButton)
        
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveButtonClicked(_:)))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r" // Return key
        saveButton.frame = NSRect(x: view.bounds.width - 100, y: 20, width: 80, height: 32)
        view.addSubview(saveButton)
    }
    
    @objc private func cancelButtonClicked(_ sender: NSButton) {
        dismiss(nil)
    }
    
    @objc private func saveButtonClicked(_ sender: NSButton) {
        // Validate input
        if companyNameTextField.stringValue.isEmpty {
            showAlert(title: "Validation Error", message: "Company name is required")
            return
        }
        
        if jobTitleTextField.stringValue.isEmpty {
            showAlert(title: "Validation Error", message: "Job title is required")
            return
        }
        
        // Create a new job application
        let newJob = JobApplication(
            id: -1, // The database will assign a proper ID
            companyName: companyNameTextField.stringValue,
            jobTitle: jobTitleTextField.stringValue,
            applicationDate: applicationDatePicker.dateValue,
            applicationDeadline: deadlineDatePicker.dateValue,
            status: statusPopUpButton.titleOfSelectedItem ?? "Applied",
            jobDescription: jobDescriptionTextView.string,
            notes: notesTextView.string,
            contactName: contactNameTextField.stringValue,
            contactEmail: contactEmailTextField.stringValue,
            contactPhone: contactPhoneTextField.stringValue,
            attachments: []
        )
        
        // Save the job application to the database
        do {
            let _ = try databaseManager.addJobApplication(newJob)
            dismiss(nil)
            onJobAdded?()
        } catch {
            print("Failed to add job application: \(error)")
            showAlert(title: "Error", message: "Failed to add job application: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
} 