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
        tf.alignment = .center
        tf.font = NSFont.systemFont(ofSize: 12)
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

    // TODO: v2 - add countdown label
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let quitButton = NSButton(title: "Quit", target: self, action: #selector(quit))
        let resetButton = NSButton(title: "Reset", target: self, action: #selector(reset))
        
        let stackView = NSStackView(views: [quitButton, resetButton])
        stackView.orientation = .horizontal
        stackView.distribution = .equalCentering
        view.addSubview(stackView, constraints: [
            equal(\.topAnchor, constant: 10),
            equal(\.centerXAnchor),
            constant(\.widthAnchor, constant: 150),
            equal(\.widthAnchor, constant: -40),
            ])

        _slider.target = self
        _slider.action = #selector(sliderValueChanged(sender:))
        view.addSubview(_slider, constraints: [
            equal(\.centerXAnchor),
            ])

        update(textField: _textField, withValue: roundedValue(for: _slider))
        view.addSubview(_textField, constraints: [
            equal(\.centerXAnchor),
            equal(\.bottomAnchor, constant: -10),
            ])

        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: _slider.topAnchor, constant: -10),
            _slider.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            _slider.bottomAnchor.constraint(equalTo: _textField.topAnchor),
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
        let hourString = value == 1 ? "hour" : "hours"
        textField.stringValue = "Reminder every \(value) \(hourString)"
    }

    @objc func quit() {
        _delegate?.quitButtonClicked()
    }
    
    @objc func reset() {
        let value = roundedValue(for: _slider)
        _delegate?.periodicityChanged(to: value)
    }
}
