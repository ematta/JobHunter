import AppKit
import Foundation

class AppController: NSObject {
    private var window: NSWindow?
    private var mainViewController: MainViewController?
    private var databaseManager: DatabaseManager?
    private var iCloudManager: iCloudManager?
    
    /**
     * Initializes and starts the application.
     *
     * This method performs the following tasks:
     * - Sets up the database manager
     * - Initializes the iCloud manager
     * - Configures the application menu
     * - Creates the main window
     * - Activates the application
     */
    func startApplication() {
        // Set up the database manager
        do {
            databaseManager = try DatabaseManager()
            print("Database initialized successfully")
        } catch {
            print("Failed to initialize database: \(error)")
            NSAlert(error: error).runModal()
            NSApp.terminate(nil)
            return
        }
        
        // Set up iCloud manager
        iCloudManager = JobHunter.iCloudManager()
        
        // Set up application menu
        setupApplicationMenu()
        
        // Create the main window
        createMainWindow()
        
        // Activate the application and bring it to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /**
     * Creates and configures the main application window.
     *
     * This method:
     * - Creates a new NSWindow with appropriate dimensions and style
     * - Sets up the MainViewController as the window's content
     * - Configures window properties like title and minimum size
     * - Makes the window visible and brings it to the front
     */
    private func createMainWindow() {
        // Create the window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "JobHunter"
        window?.center()
        
        // Create the main view controller
        mainViewController = MainViewController(
            databaseManager: databaseManager!,
            iCloudManager: iCloudManager!
        )
        
        if let contentView = mainViewController?.view {
            window?.contentView = contentView
        }
        
        // Make the window key and bring it to front
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()  // Force window to front
        
        // Set window minimum size
        window?.minSize = NSSize(width: 800, height: 600)
    }
    
    /**
     * Sets up the application's main menu.
     *
     * This method creates a standard macOS application menu with:
     * - An About menu item
     * - A separator
     * - A Quit menu item with the standard Command+Q keyboard shortcut
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