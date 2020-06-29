import AppKit
import Foundation

protocol Coordinator {
    func start()
}

// To get the app in the app store
// TODO: make this app also functional with stand alone window (not totally dependent on notifications) (per Apple review)
// TODO: Add a random stretching image to when the timer fires (to make the app more useful and to hopefully satisfy Apple's review)

// Beginner tasks
// TODO: v2 - start at login
// TODO: v2 - change timer countdown to reflect slider change
// TODO: v2 - Slider for how "push" you want the reminder text to be
// TODO: v2 - maybe add different quotes for the reminder notifications?
// TODO: v2 - add ability to back add some time because you went to a meeting or w/e

// Intermediate tasks
// TODO: v2 - changing status icon when timer changes (from dark icon to light)
// TODO: v2 - silence range (e.g., notifications don't appear between 5pm and 10am)
// TODO: v2 - donations?
// TODO: v2 - provide `show` in the alert to show user stats about their sitting/standing activity

// Other tasks
// TODO: move these todos to github
// TODO: add link to this project when open sourced

final class AppCoordinator: NSObject, Coordinator {
    private let _statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    private let _popover = NSPopover()
    private static let _storedPeriodKey = "storedPeriodKey"
    private let _initialPeriod: PeriodInHours = {
        let storedPeriod: PeriodInHours = UserDefaults.standard.double(forKey: _storedPeriodKey)
        return storedPeriod > 0 ? storedPeriod : 1
    }()
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
        _popover.contentViewController = TimerPopoverVc(delegate: self,
                                                        dataSource: self,
                                                        initialPeriodicity: _initialPeriod)

        statusButton.image = NSImage(named:"StatusBarImage1") // this api has recently changed
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
    
    private func sendTemporaryPush(notification: NSUserNotification, duration: Double = 5) {
        _notificationCenter.removeAllDeliveredNotifications()
        DispatchQueue
            .main
            .asyncAfter(deadline: DispatchTime.now() + duration) { [weak _notificationCenter] in
            _notificationCenter?.removeDeliveredNotification(notification)
        }
        _notificationCenter.scheduleNotification(notification)
    }
    
    private func sendPersistentNotification(notification: NSUserNotification) {
        _notificationCenter.removeAllDeliveredNotifications()
        _notificationCenter.scheduleNotification(notification)
    }
    
    private func createNotification(title: String, body: String) -> NSUserNotification {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.hasActionButton = false
        notification.otherButtonTitle = "Okay"
        return notification
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

        UserDefaults.standard.set(period, forKey: AppCoordinator._storedPeriodKey)
        
        _timer?.invalidate()
        let periodInSeconds = period * 60 * 60
        
        let df = DateFormatter()
        df.dateFormat = "h:mm a"
        let time = df.string(from: Date(timeIntervalSinceNow: periodInSeconds))
        
        let hourString = period == 1 ? "hour" : "hours"
        let notification = createNotification(
            title: "⏰ Updated to every \(period) \(hourString)",
            body: "Next alert set for \(time)"
        )
        sendTemporaryPush(notification: notification)

        let firstFire = Date(timeInterval: periodInSeconds, since: Date())
        let timer = Timer(fire: firstFire, interval: periodInSeconds, repeats: true) { [unowned self] _ in
            let df = DateFormatter()
            df.dateFormat = "h:mm a"
            let time = df.string(from: Date(timeIntervalSinceNow: periodInSeconds))
            let notification = self.createNotification(
                title: "Your gentle reminder to transition 🤓",
                body: "Next alert set for: \(time)"
            )
            self.sendPersistentNotification(notification: notification)
        }
        let runLoop = RunLoop.current
        runLoop.add(timer, forMode: RunLoop.Mode.default)
        _timer = timer
    }
}

extension AppCoordinator: TimerPopoverVcDataSource {
    func timeLeftUntilReminder() -> TimeInterval {
        guard let fireDate = _timer?.fireDate else { return 0 }
        return fireDate.timeIntervalSinceNow
    }
}
