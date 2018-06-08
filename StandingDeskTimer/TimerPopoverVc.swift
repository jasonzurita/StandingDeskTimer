import AppKit

typealias PeriodInHours = Double
protocol TimerPopoverVcDelegate: class {
    func quitButtonClicked()
    func periodicityChanged(to period: PeriodInHours)
}

final class TimerPopoverVc: NSViewController {
    private weak var _delegate: TimerPopoverVcDelegate?
    private let _slider: NSSlider
    private let _textField: NSTextField = {
        let tf = NSTextField()
        tf.isEditable = false
        tf.drawsBackground = false
        tf.font = NSFont.systemFont(ofSize: 16)
        tf.isBordered = false
        return tf
    }()

    init(delegate: TimerPopoverVcDelegate, initialPeriodicity period: PeriodInHours) {
        _delegate = delegate
        _slider = NSSlider(value: period, minValue: 0, maxValue: 4, target: nil, action: nil)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) { fatalError("\(#function) has not been implemented") }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        _slider.target = self
        _slider.action = #selector(sliderValueChanged(sender:))

        view.addSubview(_slider, constraints: [
            equal(\.widthAnchor, constant: -40),
            equal(\.topAnchor, constant: 15),
            equal(\.centerXAnchor),
            constant(\.widthAnchor, constant: 150),
            ])

        update(textField: _textField, withValue: roundedValue(for: _slider))

        view.addSubview(_textField, constraints: [
            equal(\.centerXAnchor),
            ])

        let button = NSButton(title: "Quit app", target: self, action: #selector(quit))
        view.addSubview(button, constraints: [
            equal(\.centerXAnchor),
            equal(\.bottomAnchor, constant: -10),
            ])

        NSLayoutConstraint.activate([
            _slider.bottomAnchor.constraint(equalTo: _textField.topAnchor),
            _textField.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -10),
            ])
    }

    @objc func sliderValueChanged(sender: Any) {
        guard let slider = sender as? NSSlider,
              let event = NSApplication.shared.currentEvent else { return }

        update(textField: _textField, withValue: roundedValue(for: slider))

        let didSliderChangingStop = event.type == .leftMouseUp || event.type == .rightMouseUp
        if didSliderChangingStop {
            let value = roundedValue(for: slider)
            _delegate?.periodicityChanged(to: value)
        }
    }

    private func roundedValue(for slider: NSSlider, to significantFigure: Double = 10) -> Double {
        let truncatedValue = Int(slider.doubleValue * significantFigure)
        return Double(truncatedValue) / significantFigure
    }

    private func update(textField: NSTextField, withValue value: Double) {
        textField.stringValue = "every \(value) hours"
    }

    @objc func quit() {
        _delegate?.quitButtonClicked()
    }
}
