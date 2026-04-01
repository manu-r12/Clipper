import SwiftUI
 
@main
struct ClipperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
 
    var body: some Scene {
        Settings { EmptyView() }
    }
}
 
final class AppDelegate: NSObject, NSApplicationDelegate {
 
    private let store = ClipboardStore()
    private var menuBarController: MenuBarController!
    private var notchController: NotchWindowController!
 
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController(store: store)
        notchController   = NotchWindowController(store: store)
    }
 
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
 
