import SwiftUI

/**
 * A SwiftUI view for creating new job applications.
 *
 * This view presents a form for the user to input details about a new job application,
 * including company name, job title, dates, and contact information.
 */
struct NewJobView: View {
    @EnvironmentObject private var databaseManager: DatabaseManager
    
    // Callbacks
    var onSave: (JobApplication) -> Void
    var onCancel: () -> Void
    
    // Form fields
    @State private var companyName: String = ""
    @State private var jobTitle: String = ""
    @State private var applicationDate: Date = Date()
    @State private var deadlineDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 7) // One week from now
    @State private var status: String = "Applied"
    @State private var jobDescription: String = ""
    @State private var notes: String = ""
    @State private var contactName: String = ""
    @State private var contactEmail: String = ""
    @State private var contactPhone: String = ""
    @State private var url: String = ""
    
    // Status options
    private let statusOptions = ["Applied", "Interviewing", "Offered", "Rejected"]
    
    // Validation and alerts
    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""
    @State private var showResetDatabaseAlert: Bool = false
    @State private var showResetSuccessAlert: Bool = false
    @State private var showResetErrorAlert: Bool = false
    @State private var resetErrorMessage: String = ""
    
    var body: some View {
        VStack {
            // Title
            Text("Add New Job Application")
                .font(.title)
                .padding(.top)
            
            ScrollView {
                VStack(spacing: 15) {
                    // Company Name
                    FormField(label: "Company Name:", value: $companyName, placeholder: "Enter company name")
                    
                    // Job Title
                    FormField(label: "Job Title:", value: $jobTitle, placeholder: "Enter job title")
                    
                    // Date Group
                    Group {
                        // Application Date
                        HStack {
                            Text("Application Date:")
                                .frame(width: 140, alignment: .leading)
                                .font(.body)
                            DatePicker("", selection: $applicationDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .padding(.vertical, 5)
                        
                        // Deadline Date
                        HStack {
                            Text("Deadline Date:")
                                .frame(width: 140, alignment: .leading)
                                .font(.body)
                            DatePicker("", selection: $deadlineDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .padding(.vertical, 5)
                        
                        // Status
                        HStack {
                            Text("Status:")
                                .frame(width: 140, alignment: .leading)
                                .font(.body)
                            Picker("", selection: $status) {
                                ForEach(statusOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            Spacer()
                        }
                        .padding(.vertical, 5)
                    }
                    
                    // Job Description
                    VStack(alignment: .leading) {
                        Text("Job Description:")
                            .font(.body)
                        TextEditor(text: $jobDescription)
                            .frame(height: 100)
                            .border(Color.gray, width: 1)
                            .padding(.bottom)
                    }
                    
                    // Notes
                    VStack(alignment: .leading) {
                        Text("Notes:")
                            .font(.body)
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .border(Color.gray, width: 1)
                            .padding(.bottom)
                    }
                    
                    // Contact Information Section
                    Group {
                        Text("Contact Information")
                            .font(.headline)
                            .padding(.top)
                        
                        FormField(label: "Name:", value: $contactName, placeholder: "Contact name")
                        FormField(label: "Email:", value: $contactEmail, placeholder: "Contact email")
                        FormField(label: "Phone:", value: $contactPhone, placeholder: "Contact phone")
                        FormField(label: "Job URL:", value: $url, placeholder: "https://...")
                    }
                }
                .padding()
            }
            
            // Buttons
            HStack {
                // Debug button - in a real app, you might want to remove this
                Button("Reset Database") {
                    showResetDatabaseAlert = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    saveJob()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
        // Validation alert
        .alert("Validation Error", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
        // Reset database confirmation alert
        .alert("Reset Database", isPresented: $showResetDatabaseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset Database", role: .destructive) {
                performDatabaseReset()
            }
        } message: {
            Text("This will delete all data in the database. Are you sure you want to continue?")
        }
        // Reset success alert
        .alert("Database Reset", isPresented: $showResetSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Database has been reset successfully.")
        }
        // Reset error alert
        .alert("Reset Failed", isPresented: $showResetErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(resetErrorMessage)
        }
    }
    
    /**
     * Validates the form input.
     *
     * - Returns: True if the form is valid, false otherwise
     */
    private func validateForm() -> Bool {
        if companyName.isEmpty {
            validationMessage = "Company name is required"
            showValidationAlert = true
            return false
        }
        
        if jobTitle.isEmpty {
            validationMessage = "Job title is required"
            showValidationAlert = true
            return false
        }
        
        return true
    }
    
    /**
     * Saves the job application to the database.
     */
    private func saveJob() {
        // Validate input
        if !validateForm() {
            return
        }
        
        // Create a new job application
        let newJob = JobApplication(
            id: -1, // The database will assign a proper ID
            companyName: companyName,
            jobTitle: jobTitle,
            applicationDate: applicationDate,
            applicationDeadline: deadlineDate,
            status: status,
            jobDescription: jobDescription,
            notes: notes,
            contactName: contactName,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            url: url,
            attachments: []
        )
        
        // Pass to callback for saving
        onSave(newJob)
    }
    
    /**
     * Performs the actual database reset.
     */
    private func performDatabaseReset() {
        do {
            try databaseManager.resetDatabase()
            showResetSuccessAlert = true
        } catch {
            print("Failed to reset database: \(error)")
            resetErrorMessage = "Failed to reset database: \(error.localizedDescription)"
            showResetErrorAlert = true
        }
    }
}

/**
 * A reusable view for form fields.
 */
struct FormField: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 140, alignment: .leading)
                .font(.body)
            
            TextField(placeholder, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.vertical, 5)
    }
} 