import UIKit


class CalendarDayToggleButton: UIButton {

    typealias TouchUpInsideAction = (CalendarDayToggleButton) -> ()

    /// The number of the day within the week.
    ///
    let weekday: BloggingRemindersScheduler.Weekday

    /// A closure that will be called when the button is tapped.
    ///
    let action: TouchUpInsideAction

    // MARK: - Initialization

    init(
        weekday: BloggingRemindersScheduler.Weekday,
        dayName: String,
        isSelected: Bool,
        action: @escaping TouchUpInsideAction) {

        self.weekday = weekday
        self.action = action

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        setTitle(dayName, for: .normal)

        configureStyle()
        configureConstraints()

        self.isSelected = isSelected

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIView

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.size.width / 2
    }

    // MARK: - Configuration

    private func configureStyle() {
        setTitleColor(.secondaryLabel, for: .normal)
        setTitleColor(.white, for: .highlighted)
        setTitleColor(.white, for: [.highlighted, .selected])
        setTitleColor(.white, for: .selected)

        titleLabel?.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(greaterThanOrEqualToConstant: Metrics.toggleSize),
            heightAnchor.constraint(greaterThanOrEqualToConstant: Metrics.toggleSize),
            widthAnchor.constraint(equalTo: heightAnchor),
        ])
    }

    // MARK: - UIControl

    override var isSelected: Bool {
        didSet {
            backgroundColor = backgroundColorForCurrentState
            setNeedsDisplay()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = backgroundColorForCurrentState
            setNeedsDisplay()
        }
    }

    // MARK: - Misc

    private var backgroundColorForCurrentState: UIColor {
        switch (isSelected, isHighlighted) {
        case (false, false):
            return .quaternaryBackground
        case (true, false):
            return UIColor.muriel(name: .green, .shade20)
        case (false, true):
            return UIColor.muriel(name: .green, .shade10)
        case (true, true):
            return UIColor.muriel(name: .green, .shade10)
        }
    }

    @objc func tapped() {
        isSelected.toggle()

        action(self)
    }
}

private enum Metrics {
    static let toggleSize: CGFloat = 55.0
}
