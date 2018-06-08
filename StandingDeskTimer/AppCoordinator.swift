import AppKit
import Foundation

protocol Coordinator {
    func start()
}

final class AppCoordinator: NSObject, Coordinator {
    private let _statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    private let _popover = NSPopover()
    private let _oneHourInSeconds: TimeInterval = 60 * 60
    private let _eventMonitor: EventMonitor
    private let _notificationCenter: NSUserNotificationCenter

    init(eventMonitor: EventMonitor, notificationCenter: NSUserNotificationCenter = .default) {
        _eventMonitor = eventMonitor
        _notificationCenter = notificationCenter
        super.init()

    }

    func start() {
        guard let statusButton = _statusItem.button else {
            fatalError("No status bar button to use")
        }

        _notificationCenter.delegate = self
        _popover.contentViewController = TimerPopoverVc(delegate: self)

        statusButton.image = NSImage(named:NSImage.Name("StatusBarImage")) // this api has recently changed
        statusButton.action = #selector(togglePopover(_:))
        statusButton.target = self

        let firstFire = Date(timeInterval: _oneHourInSeconds, since: Date())
        let timer = Timer(fire: firstFire, interval: _oneHourInSeconds, repeats: true) { [_notificationCenter] _ in
            _notificationCenter.removeAllDeliveredNotifications()
            let notification:NSUserNotification = NSUserNotification()
            notification.title = "Standing desk reminder!"
            notification.informativeText = "Time to transition"
            _notificationCenter.scheduleNotification(notification)
        }
        let runLoop = RunLoop.current
        runLoop.add(timer, forMode: .defaultRunLoopMode)
    }

    deinit {
        print("deinit")
    }

    @objc func togglePopover(_ sender: Any?) {
        if _popover.isShown {
            closePopover(sender: sender)
            _eventMonitor.stop()
        } else {
            showPopover(sender: sender)
            _eventMonitor.start(handler: { [weak self] event in
                guard let strongSelf = self else { return }
                strongSelf.closePopover(sender: event)
            })
        }
    }

    private func closePopover(sender: Any?) {
        _popover.performClose(sender)
    }

    private func showPopover(sender: Any?) {
        if let button = _statusItem.button {
            _popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
}

extension AppCoordinator: NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

extension AppCoordinator: TimerPopoverVcDelegate {
    func quitButtonClicked() {
        NSApplication.shared.terminate(nil)
    }
}
