import AppKit

typealias PeriodInHours = Double
protocol TimerPopoverVcDelegate: class {
    func quitButtonClicked()
    func periodicityChanged(to period: PeriodInHours)
}

protocol TimerPopoverVcDataSource: class {
    func timeLeftUntilReminder() -> TimeInterval
}

final class TimerPopoverVc: NSViewController {
    private weak var _delegate: TimerPopoverVcDelegate?
    private weak var _dataSource: TimerPopoverVcDataSource?
    private let _slider: NSSlider
    private let _timerTextField: NSTextField = {
        let tf = NSTextField()
        tf.isEditable = false
        tf.drawsBackground = false
        tf.alignment = .center
        tf.font = NSFont.systemFont(ofSize: 24)
        tf.isBordered = false
        return tf
    }()
    private weak var _timer: Timer?
    private let _sliderDetailTextField: NSTextField = {
        let tf = NSTextField()
        tf.isEditable = false
        tf.drawsBackground = false
        tf.alignment = .center
        tf.font = NSFont.systemFont(ofSize: 12)
        tf.isBordered = false
        return tf
    }()

    init(delegate: TimerPopoverVcDelegate,
         dataSource: TimerPopoverVcDataSource,
         initialPeriodicity period: PeriodInHours) {
        _delegate = delegate
        _dataSource = dataSource
        _slider = NSSlider(value: period, minValue: 0.1, maxValue: 4, target: nil, action: nil)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) { fatalError("\(#function) has not been implemented") }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        resetTimer()
    }
    
    private func resetTimer() {
        _timer?.invalidate()
        update(timerTextField: _timerTextField)
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.update(timerTextField: strongSelf._timerTextField)
        }
        let runLoop = RunLoop.current
        runLoop.add(timer, forMode: .defaultRunLoopMode)
        _timer = timer
    }

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
        
        view.addSubview(_timerTextField, constraints: [
            equal(\.widthAnchor),
            equal(\.centerXAnchor),
            ])
        
        _slider.target = self
        _slider.action = #selector(sliderValueChanged(sender:))
        view.addSubview(_slider, constraints: [
            equal(\.centerXAnchor),
            ])

        update(sliderDetailTextField: _sliderDetailTextField, withValue: roundedValue(for: _slider))
        view.addSubview(_sliderDetailTextField, constraints: [
            equal(\.centerXAnchor),
            equal(\.bottomAnchor, constant: -10),
            ])

        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: _timerTextField.topAnchor, constant: -10),
            _slider.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            _timerTextField.bottomAnchor.constraint(equalTo: _slider.topAnchor, constant: -10),
            _slider.bottomAnchor.constraint(equalTo: _sliderDetailTextField.topAnchor),
            ])
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        _timer?.invalidate()
        _timer = nil
    }

    @objc func sliderValueChanged(sender: Any) {
        guard let slider = sender as? NSSlider,
              let event = NSApplication.shared.currentEvent else { return }

        update(sliderDetailTextField: _sliderDetailTextField, withValue: roundedValue(for: slider))

        let didSliderChangingStop = event.type == .leftMouseUp || event.type == .rightMouseUp
        if didSliderChangingStop {
            let value = roundedValue(for: slider)
            _delegate?.periodicityChanged(to: value)
            resetTimer()
        }
    }

    private func roundedValue(for slider: NSSlider, to significantFigure: Double = 10) -> Double {
        let truncatedValue = Int(slider.doubleValue * significantFigure)
        return Double(truncatedValue) / significantFigure
    }

    private func update(sliderDetailTextField: NSTextField, withValue value: Double) {
        let hourString = value == 1 ? "hour" : "hours"
        sliderDetailTextField.stringValue = "Reminder every \(value) \(hourString)"
    }
    
    private func update(timerTextField: NSTextField) {
        let timeLeftInSeconds = _dataSource?.timeLeftUntilReminder() ?? 0
        let hours = timeLeftInSeconds.stringFromSecondsToHours(zeroPadding: true)
        let minutes = hours.remainder.stringFromSecondsToMinutes(zeroPadding: true)
        let seconds = minutes.remainder.stringFromSecondsToSeconds(zeroPadding: true)
        
        timerTextField.stringValue = hours.string + ":" + minutes.string + ":" + seconds.string
    }

    @objc func quit() {
        _delegate?.quitButtonClicked()
    }
    
    @objc func reset() {
        let value = roundedValue(for: _slider)
        _delegate?.periodicityChanged(to: value)
        resetTimer()
    }
}
