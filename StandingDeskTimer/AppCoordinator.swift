import AppKit
import Foundation

protocol Coordinator {
    func start()
}

// TODO: v1 - allow resetting of timer (button + notification)
// TODO: v2 - silence range (e.g., notifications don't appear between 5pm and 10am)
// TODO: v2 - icon change based on time to transition
// TODO: v2 - donations?

final class AppCoordinator: NSObject, Coordinator {
    private let _statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    private let _popover = NSPopover()
    private let _initialPeriod: PeriodInHours = 1
    private let _eventMonitor: EventMonitor
    private let _notificationCenter: NSUserNotificationCenter
    private weak var _timer: Timer?

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
        _popover.contentViewController = TimerPopoverVc(delegate: self, initialPeriodicity: _initialPeriod)

        statusButton.image = NSImage(named:NSImage.Name("StatusBarImage")) // this api has recently changed
        statusButton.action = #selector(togglePopover(_:))
        statusButton.target = self

        periodicityChanged(to: _initialPeriod)
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
    
    private func sendPush(title: String, body: String) {

        _notificationCenter.removeAllDeliveredNotifications()
        
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        
        _notificationCenter.scheduleNotification(notification)
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

    func periodicityChanged(to period: PeriodInHours) {
        print("New period: \(period) hours")

        _timer?.invalidate()
        
        sendPush(title: "Timer updated!", body: "You will be reminded every \(period) hours")

        let periodInSeconds = period * 60 * 60

        let firstFire = Date(timeInterval: periodInSeconds, since: Date())
        let timer = Timer(fire: firstFire, interval: periodInSeconds, repeats: true) { [unowned self] _ in
            // TODO: v1 - format timestamp for notification
            self.sendPush(title: "Your gentle reminder to transition 🤓", body: "\(Date())")
        }
        let runLoop = RunLoop.current
        runLoop.add(timer, forMode: .defaultRunLoopMode)
        _timer = timer
    }
}
