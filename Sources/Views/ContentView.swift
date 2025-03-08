import SwiftUI

/**
 * Main content view for the JobHunter application.
 * 
 * This view serves as the container for the entire application UI,
 * with a split view containing the job list on the left and job details on the right.
 */
struct ContentView: View {
    @EnvironmentObject private var databaseManager: DatabaseManager
    @EnvironmentObject private var cloudManager: CloudManager
    
    @State private var jobApplications: [JobApplication] = []
    @State private var filteredJobApplications: [JobApplication] = []
    @State private var selectedJob: JobApplication?
    @State private var searchText: String = ""
    @State private var selectedStatus: Int = 0 // 0 = All, 1 = Applied, 2 = Interviewing, etc.
    @State private var isAddingNewJob: Bool = false
    
    private let statusOptions = ["All", "Applied", "Interviewing", "Offered", "Rejected"]
    
    var body: some View {
        NavigationView {
            // Left panel - Job list
            VStack {
                // Search and filter controls
                HStack {
                    TextField("Search jobs...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { _ in filterJobs() }
                    
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(0..<statusOptions.count, id: \.self) { index in
                            Text(statusOptions[index])
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedStatus) { _ in filterJobs() }
                }
                .padding([.horizontal, .top])
                
                // Job list
                List(filteredJobApplications, id: \.id, selection: $selectedJob) { job in
                    Text(job.companyName)
                        .font(.body)
                }
                .listStyle(SidebarListStyle())
                
                // Add/Remove buttons
                HStack {
                    Button("Add Job") {
                        isAddingNewJob = true
                    }
                    
                    Button("Remove Job") {
                        if let selectedJob = selectedJob {
                            deleteJob(selectedJob)
                        }
                    }
                    .disabled(selectedJob == nil)
                    
                    Spacer()
                }
                .padding()
            }
            .frame(minWidth: 250)
            
            // Right panel - Job details
            if let job = selectedJob {
                JobDetailView(job: job, onUpdate: { updatedJob in
                    updateJob(updatedJob)
                })
            } else {
                Text("Select a job to view details")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.darkGray))
            }
        }
        .onAppear {
            loadJobs()
        }
        .sheet(isPresented: $isAddingNewJob) {
            NewJobView(onSave: { newJob in
                addJob(newJob)
                isAddingNewJob = false
            }, onCancel: {
                isAddingNewJob = false
            })
        }
    }
    
    /**
     * Loads all job applications from the database.
     */
    private func loadJobs() {
        do {
            jobApplications = try databaseManager.getAllJobApplications()
            filterJobs()
        } catch {
            print("Failed to load job applications: \(error)")
        }
    }
    
    /**
     * Filters the job applications based on search text and selected status.
     */
    private func filterJobs() {
        filteredJobApplications = jobApplications.filter { job in
            let matchesSearch = searchText.isEmpty || 
                job.companyName.lowercased().contains(searchText.lowercased()) || 
                job.jobTitle.lowercased().contains(searchText.lowercased()) ||
                job.notes.lowercased().contains(searchText.lowercased())
            
            let matchesStatus: Bool
            if selectedStatus == 0 {
                matchesStatus = true  // "All" option
            } else {
                let selectedStatusText = statusOptions[selectedStatus]
                matchesStatus = job.status == selectedStatusText
            }
            
            return matchesSearch && matchesStatus
        }
    }
    
    /**
     * Adds a new job application to the database.
     */
    private func addJob(_ job: JobApplication) {
        do {
            let _ = try databaseManager.addJobApplication(job)
            loadJobs()
        } catch {
            print("Failed to add job: \(error)")
        }
    }
    
    /**
     * Updates an existing job application in the database.
     */
    private func updateJob(_ job: JobApplication) {
        do {
            try databaseManager.updateJobApplication(job)
            loadJobs()
            
            // Re-select the job after update
            selectedJob = jobApplications.first(where: { $0.id == job.id })
        } catch {
            print("Failed to update job: \(error)")
        }
    }
    
    /**
     * Deletes a job application from the database.
     */
    private func deleteJob(_ job: JobApplication) {
        do {
            try databaseManager.deleteJobApplication(job.id)
            loadJobs()
            selectedJob = nil
        } catch {
            print("Failed to delete job: \(error)")
        }
    }
} 