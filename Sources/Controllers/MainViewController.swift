import AppKit
import Foundation

class MainViewController: NSViewController {
    private let databaseManager: DatabaseManager
    private let iCloudManager: iCloudManager
    
    private var jobsTableView: NSTableView!
    private var jobDetailView: JobDetailView!
    private var searchField: NSSearchField!
    private var statusSegmentedControl: NSSegmentedControl!
    private var jobApplications: [JobApplication] = []
    private var filteredJobApplications: [JobApplication] = []
    
    /**
     * Initializes a new MainViewController with the required dependencies.
     *
     * - Parameters:
     *   - databaseManager: The database manager used to interact with the application's data
     *   - iCloudManager: The iCloud manager used for cloud synchronization
     */
    init(databaseManager: DatabaseManager, iCloudManager: iCloudManager) {
        self.databaseManager = databaseManager
        self.iCloudManager = iCloudManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     * Creates and sets up the main view.
     *
     * This method is called during the view controller's initialization process.
     */
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 700))
        view.wantsLayer = true
    }
    
    /**
     * Called after the view controller's view has been loaded into memory.
     *
     * This method sets up the UI components and loads the initial job application data.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setupUI()
        
        // Load data
        loadJobApplications()
    }
    
    /**
     * Sets up the user interface components.
     *
     * Creates and configures the split view that contains the left panel (job list)
     * and the right panel (job details).
     */
    private func setupUI() {
        // Create a split view
        let splitView = NSSplitView(frame: view.bounds)
        splitView.autoresizingMask = [.width, .height]
        splitView.dividerStyle = .thin
        splitView.isVertical = true
        view.addSubview(splitView)
        
        // Create the left panel (jobs list)
        let leftPanel = createLeftPanel()
        
        // Create the right panel (job details)
        let rightPanel = createRightPanel()
        
        // Add panels to split view
        splitView.addArrangedSubview(leftPanel)
        splitView.addArrangedSubview(rightPanel)
        
        // Set up split view position and hold positions
        splitView.setPosition(300, ofDividerAt: 0)
        
        // Prevent the left panel from resizing
        if let leftSplitViewItem = splitView.subviews.first {
            splitView.setHoldingPriority(NSLayoutConstraint.Priority(250), forSubviewAt: 0)
        }
    }
    
    /**
     * Creates and configures the left panel containing the job list.
     *
     * This panel contains:
     * - A search field for filtering jobs
     * - A segmented control for filtering by job status
     * - A table view displaying the list of job applications
     * - Buttons for adding and removing jobs
     *
     * - Returns: The configured left panel view
     */
    private func createLeftPanel() -> NSView {
        let panel = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: view.bounds.height))
        panel.wantsLayer = true
        panel.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        // Create the search field
        searchField = NSSearchField(frame: NSRect(x: 10, y: panel.bounds.height - 40, width: panel.bounds.width - 20, height: 30))
        searchField.placeholderString = "Search jobs..."
        searchField.target = self
        searchField.action = #selector(searchFieldChanged(_:))
        searchField.autoresizingMask = [.width, .minYMargin]
        panel.addSubview(searchField)
        
        // Create the table view - simplify to just display company names
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 50, width: panel.bounds.width, height: panel.bounds.height - 90))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        
        jobsTableView = NSTableView(frame: NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height))
        jobsTableView.autoresizingMask = [.width, .height]
        jobsTableView.backgroundColor = NSColor.darkGray
        
        // Create company column - single column for simplified view
        let companyColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("companyColumn"))
        companyColumn.title = "Company"
        companyColumn.width = scrollView.contentSize.width - 20
        jobsTableView.addTableColumn(companyColumn)
        
        jobsTableView.delegate = self
        jobsTableView.dataSource = self
        
        scrollView.documentView = jobsTableView
        panel.addSubview(scrollView)
        
        // Create buttons for adding and removing jobs
        let addButton = NSButton(frame: NSRect(x: 10, y: 10, width: 100, height: 30))
        addButton.title = "Add Job"
        addButton.bezelStyle = .rounded
        addButton.target = self
        addButton.action = #selector(addJob(_:))
        panel.addSubview(addButton)
        
        let removeButton = NSButton(frame: NSRect(x: 120, y: 10, width: 100, height: 30))
        removeButton.title = "Remove Job"
        removeButton.bezelStyle = .rounded
        removeButton.target = self
        removeButton.action = #selector(removeJob(_:))
        panel.addSubview(removeButton)
        
        return panel
    }
    
    /**
     * Creates and configures the right panel containing the job details.
     *
     * This panel displays the details of the currently selected job application.
     *
     * - Returns: The configured right panel view
     */
    private func createRightPanel() -> NSView {
        // Adjust the width to better utilize space
        let panel = NSView(frame: NSRect(x: 0, y: 0, width: view.bounds.width - 300, height: view.bounds.height))
        panel.wantsLayer = true
        panel.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        // Create the job detail view
        jobDetailView = JobDetailView(frame: panel.bounds, databaseManager: databaseManager, iCloudManager: iCloudManager)
        jobDetailView.autoresizingMask = [.width, .height]
        jobDetailView.delegate = self
        panel.addSubview(jobDetailView)
        
        return panel
    }
    
    // MARK: - Data Loading
    
    /**
     * Loads all job applications from the database.
     *
     * This method retrieves all job applications, updates the table view,
     * and selects the first job if available.
     */
    private func loadJobApplications() {
        do {
            jobApplications = try databaseManager.getAllJobApplications()
            
            // Apply current filter
            filteredJobApplications = jobApplications
            
            // Apply search filter if search text is not empty
            let searchText = searchField.stringValue
            if !searchText.isEmpty {
                filteredJobApplications = filteredJobApplications.filter { job in
                    job.companyName.lowercased().contains(searchText.lowercased()) ||
                    job.jobTitle.lowercased().contains(searchText.lowercased())
                }
            }
            
            jobsTableView.reloadData()
            
            // Select the first job if available
            if let firstJob = filteredJobApplications.first {
                let indexSet = IndexSet(integer: 0)
                jobsTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
                jobDetailView.display(jobApplication: firstJob)
            }
        } catch {
            print("Failed to load job applications: \(error)")
            showAlert(title: "Error", message: "Failed to load job applications: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Actions
    
    /**
     * Handles changes to the search field.
     *
     * Called when the user types in the search field to filter job applications.
     *
     * - Parameter sender: The search field that triggered the action
     */
    @objc private func searchFieldChanged(_ sender: NSSearchField) {
        filterJobApplications()
    }
    
    /**
     * Handles changes to the status filter.
     *
     * Called when the user selects a different job status segment.
     *
     * - Parameter sender: The segmented control that triggered the action
     */
    @objc private func statusFilterChanged(_ sender: NSSegmentedControl) {
        filterJobApplications()
    }
    
    /**
     * Filters the job applications based on search text and selected status.
     *
     * This method applies the current search field text and selected status
     * filter to the list of job applications and updates the table view.
     */
    private func filterJobApplications() {
        let searchText = searchField.stringValue.lowercased()
        let selectedSegment = statusSegmentedControl.selectedSegment
        
        filteredJobApplications = jobApplications.filter { job in
            let matchesSearch = searchText.isEmpty || 
                                job.companyName.lowercased().contains(searchText) || 
                                job.jobTitle.lowercased().contains(searchText) ||
                                job.notes.lowercased().contains(searchText)
            
            let matchesStatus: Bool
            if selectedSegment == 0 {
                matchesStatus = true
            } else {
                let statusArray = ["Applied", "Interviewing", "Offered", "Rejected"]
                matchesStatus = job.status == statusArray[selectedSegment - 1]
            }
            
            return matchesSearch && matchesStatus
        }
        
        jobsTableView.reloadData()
    }
    
    /**
     * Handles the add job button action.
     *
     * Presents a sheet to create a new job application.
     *
     * - Parameter sender: The button that triggered the action
     */
    @objc private func addJob(_ sender: NSButton) {
        let newJobController = NewJobViewController(databaseManager: databaseManager)
        presentAsSheet(newJobController)
        
        // Reload the data after the sheet is dismissed
        newJobController.onJobAdded = { [weak self] in
            self?.loadJobApplications()
        }
    }
    
    @objc private func removeJob(_ sender: NSButton) {
        let selectedRow = jobsTableView.selectedRow
        guard selectedRow >= 0, selectedRow < filteredJobApplications.count else {
            showAlert(title: "Error", message: "Please select a job to remove")
            return
        }
        
        let job = filteredJobApplications[selectedRow]
        
        let alert = NSAlert()
        alert.messageText = "Remove Job Application"
        alert.informativeText = "Are you sure you want to remove the job application for \(job.jobTitle) at \(job.companyName)?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            do {
                try databaseManager.deleteJobApplication(job.id)
                loadJobApplications()
            } catch {
                print("Failed to delete job application: \(error)")
                showAlert(title: "Error", message: "Failed to delete job application: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     * Called when a notification about a job application being updated is received.
     *
     * This method reloads the job applications and maintains the current selection.
     */
    @objc private func jobApplicationUpdated(_ notification: Notification) {
        let selectedRow = jobsTableView.selectedRow
        let selectedJobId = selectedRow >= 0 && selectedRow < filteredJobApplications.count ? filteredJobApplications[selectedRow].id : -1
        
        loadJobApplications()
        
        // Restore selection if possible
        if selectedJobId != -1 {
            for (index, job) in filteredJobApplications.enumerated() {
                if job.id == selectedJobId {
                    jobsTableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
                    jobDetailView.display(jobApplication: job)
                    break
                }
            }
        }
    }
    
    /**
     * Called when the user selects a job in the table view.
     *
     * This method loads the selected job into the detail view.
     */
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = jobsTableView.selectedRow
        
        if selectedRow >= 0 && selectedRow < filteredJobApplications.count {
            let selectedJob = filteredJobApplications[selectedRow]
            jobDetailView.display(jobApplication: selectedJob)
        } else {
            jobDetailView.display(jobApplication: nil)
        }
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - NSTableViewDelegate & NSTableViewDataSource

extension MainViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredJobApplications.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filteredJobApplications.count else { return nil }
        
        let job = filteredJobApplications[row]
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
        
        if identifier.rawValue == "companyColumn" {
            textField.stringValue = job.companyName
        }
        
        return cell
    }
}

// MARK: - JobDetailViewDelegate

extension MainViewController: JobDetailViewDelegate {
    /**
     * Called when a job application is updated in the detail view.
     *
     * This method updates the job in the database and reloads the list.
     */
    func jobDetailViewDidUpdate(_ jobApplication: JobApplication) {
        do {
            try databaseManager.updateJobApplication(jobApplication)
            loadJobApplications()
            
            // Restore selection
            for (index, job) in filteredJobApplications.enumerated() {
                if job.id == jobApplication.id {
                    jobsTableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
                    break
                }
            }
        } catch {
            print("Failed to update job application: \(error)")
        }
    }
} 