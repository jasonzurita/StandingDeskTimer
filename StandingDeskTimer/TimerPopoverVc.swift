import AppKit

protocol TimerPopoverVcDelegate: class {
    func quitButtonClicked()
}

final class TimerPopoverVc: NSViewController {
    private weak var _delegate: TimerPopoverVcDelegate?
    init(delegate: TimerPopoverVcDelegate) {
        _delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) { fatalError("\(#function) has not been implemented") }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = NSButton(title: "Quit app", target: self, action: #selector(quit))
        view.addSubview(button, constraints: [
            equal(\.widthAnchor, constant: -20),
            equal(\.heightAnchor, constant: -20),
            equal(\.centerXAnchor),
            equal(\.centerYAnchor),
            ])
    }

    @objc func quit() {
        _delegate?.quitButtonClicked()
    }
}
