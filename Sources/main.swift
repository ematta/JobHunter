import AppKit
import Foundation

// Create an NSApplicationMain replacement to launch our app properly
class AppDelegate: NSObject, NSApplicationDelegate {
    private let appController = AppController()
    
    /**
     * Called when the application has finished launching.
     *
     * This method serves as the main entry point for the application's logic after
     * the initial launch process is complete. It calls the appController to start
     * the application flow.
     *
     * - Parameter notification: A notification object containing information about
     *                          the application launch
     */
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize and start the application
        appController.startApplication()
    }
    
    /**
     * Determines whether the application should terminate after all windows are closed.
     *
     * This method controls the application lifecycle by specifying whether the app should
     * quit when there are no open windows left.
     *
     * - Parameter sender: The NSApplication instance that sent this message
     * - Returns: Boolean value indicating that the application should terminate (true)
     *           when all windows are closed
     */
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// Configure the application
let app = NSApplication.shared
app.setActivationPolicy(.regular)

// Create and set the app delegate
let delegate = AppDelegate()
app.delegate = delegate

// Run the application 
app.run() 