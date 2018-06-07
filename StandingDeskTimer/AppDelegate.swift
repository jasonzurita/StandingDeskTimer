import Cocoa

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let coordinator: Coordinator = {
        let em = EventMonitor(mask: [.leftMouseDown, .rightMouseDown])
        return AppCoordinator(eventMonitor: em)
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        coordinator.start()
    }
}
