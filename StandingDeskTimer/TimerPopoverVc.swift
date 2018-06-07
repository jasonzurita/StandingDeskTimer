import AppKit

final class TimerPopoverVc: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) { fatalError("\(#function) has not been implemented") }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
