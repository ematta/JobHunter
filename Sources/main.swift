import SwiftUI
import AppKit
import Foundation

// Entry point for the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

// App delegate to handle application lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    // Store the managers as properties to keep them alive
    private let databaseManager: DatabaseManager
    private let cloudManager: CloudManager
    private var window: NSWindow?
    
    override init() {
        // Initialize database manager
        do {
            self.databaseManager = try DatabaseManager()
            print("Database initialized successfully")
        } catch {
            print("Failed to initialize database: \(error)")
            // We can't show an alert here as NSApp is not yet ready
            exit(1)
        }
        
        // Initialize cloud manager
        self.cloudManager = CloudManager()
        
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()
            .environmentObject(databaseManager)
            .environmentObject(cloudManager)
        
        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window?.center()
        window?.title = "JobHunter"
        
        // Create hosting controller and set as content view
        let hostingController = NSHostingController(rootView: contentView)
        window?.contentView = hostingController.view
        window?.makeKeyAndOrderFront(nil)
        
        // Set up application menu
        setupApplicationMenu()
        
        // Activate the app
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    /**
     * Sets up the application's main menu.
     */
    private func setupApplicationMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        
        let appName = "JobHunter"
        
        // About item
        let aboutMenuItem = NSMenuItem(title: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(aboutMenuItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitMenuItem = NSMenuItem(title: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitMenuItem)
        
        // Set the menu
        NSApplication.shared.mainMenu = mainMenu
    }
}

// Make DatabaseManager conform to ObservableObject so it can be used with @EnvironmentObject
extension DatabaseManager: ObservableObject {} 