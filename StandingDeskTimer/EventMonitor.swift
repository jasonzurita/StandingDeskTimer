import Cocoa

final class EventMonitor {
    private var _monitor: Any?
    private let _mask: NSEvent.EventTypeMask

    public init(mask: NSEvent.EventTypeMask) {
        self._mask = mask
    }

    deinit {
        stop()
    }

    func start(handler: @escaping (NSEvent) -> Void) {
        _monitor = NSEvent.addGlobalMonitorForEvents(matching: _mask, handler: handler)
    }

    func stop() {
        guard let m = _monitor else { return }
        NSEvent.removeMonitor(m)
        _monitor = nil
    }
}
