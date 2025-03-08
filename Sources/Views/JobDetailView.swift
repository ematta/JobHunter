import SwiftUI

/**
 * A SwiftUI view that displays and allows editing of job application details.
 *
 * This view includes fields for all job application properties and handles
 * the display, editing, and attachment management for a job application.
 */
struct JobDetailView: View {
    @EnvironmentObject private var databaseManager: DatabaseManager
    @EnvironmentObject private var cloudManager: CloudManager
    
    private let job: JobApplication
    private let onUpdate: (JobApplication) -> Void
    
    @State private var isEditMode: Bool = false
    @State private var companyName: String
    @State private var applicationDate: Date
    @State private var deadlineDate: Date
    @State private var status: String
    @State private var jobDescription: String
    @State private var contactName: String
    @State private var contactEmail: String
    @State private var contactPhone: String
    @State private var url: String
    
    // Define available status options
    private let statusOptions = ["Applied", "Interviewing", "Offered", "Rejected", "Accepted"]
    
    /**
     * Initializes the job detail view with a job application and update handler.
     *
     * - Parameters:
     *   - job: The job application to display
     *   - onUpdate: A callback function to handle job updates
     */
    init(job: JobApplication, onUpdate: @escaping (JobApplication) -> Void) {
        self.job = job
        self.onUpdate = onUpdate
        
        // Initialize state variables with job data
        _companyName = State(initialValue: job.companyName)
        _applicationDate = State(initialValue: job.applicationDate)
        _deadlineDate = State(initialValue: job.applicationDeadline)
        _status = State(initialValue: job.status)
        _jobDescription = State(initialValue: job.jobDescription)
        _contactName = State(initialValue: job.contactName)
        _contactEmail = State(initialValue: job.contactEmail)
        _contactPhone = State(initialValue: job.contactPhone)
        _url = State(initialValue: job.url)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Edit mode toggle
                HStack {
                    Spacer()
                    Toggle("Enable Editing", isOn: $isEditMode)
                        .toggleStyle(SwitchToggleStyle())
                        .padding(.trailing)
                }
                
                // Company name
                DetailField(label: "Company:", value: $companyName, isEditable: isEditMode)
                
                // Application date
                HStack {
                    Text("Application Date:")
                        .frame(width: 150, alignment: .leading)
                        .font(.body)
                    DatePicker("", selection: $applicationDate, displayedComponents: .date)
                        .labelsHidden()
                        .disabled(!isEditMode)
                }
                
                // Deadline date
                HStack {
                    Text("Deadline Date:")
                        .frame(width: 150, alignment: .leading)
                        .font(.body)
                    DatePicker("", selection: $deadlineDate, displayedComponents: .date)
                        .labelsHidden()
                        .disabled(!isEditMode)
                }
                
                // Status
                HStack {
                    Text("Status:")
                        .frame(width: 150, alignment: .leading)
                        .font(.body)
                    Picker("", selection: $status) {
                        ForEach(statusOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .disabled(!isEditMode)
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Contact information
                DetailField(label: "Name:", value: $contactName, isEditable: isEditMode)
                DetailField(label: "Email:", value: $contactEmail, isEditable: isEditMode)
                DetailField(label: "Phone:", value: $contactPhone, isEditable: isEditMode)
                DetailField(label: "Job URL:", value: $url, isEditable: isEditMode)
                
                // Job description
                VStack(alignment: .leading) {
                    Text("Job Description:")
                        .font(.body)
                    
                    if isEditMode {
                        TextEditor(text: $jobDescription)
                            .font(.body)
                            .frame(minHeight: 200)
                            .border(Color.gray, width: 1)
                    } else {
                        ScrollView {
                            Text(jobDescription)
                                .font(.body)
                                .padding(8)
                        }
                        .frame(minHeight: 200)
                        .border(Color.gray, width: 1)
                    }
                }
                
                // Save button
                if isEditMode {
                    HStack {
                        Spacer()
                        Button("Save Changes") {
                            saveChanges()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
            }
            .padding()
        }
        .background(Color(.darkGray))
    }
    
    /**
     * Saves the changes made to the job application.
     */
    private func saveChanges() {
        // Create an updated job with the current field values
        let updatedJob = JobApplication(
            id: job.id,
            companyName: companyName,
            jobTitle: job.jobTitle, // Job title is not editable in the detail view
            applicationDate: applicationDate,
            applicationDeadline: deadlineDate,
            status: status,
            jobDescription: jobDescription,
            notes: job.notes, // Notes are not displayed in the detail view
            contactName: contactName,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            url: url,
            attachments: job.attachments
        )
        
        // Notify parent view about the update
        onUpdate(updatedJob)
        
        // Disable edit mode after saving
        isEditMode = false
    }
}

/**
 * A reusable view for displaying a labeled text field in the detail view.
 */
struct DetailField: View {
    let label: String
    @Binding var value: String
    let isEditable: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 150, alignment: .leading)
                .font(.body)
            
            if isEditable {
                TextField("", text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(value)
                    .font(.body)
            }
        }
    }
} 