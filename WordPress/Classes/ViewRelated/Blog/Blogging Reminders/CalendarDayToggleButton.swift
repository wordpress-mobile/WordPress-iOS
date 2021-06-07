import UIKit


class CalendarDayToggleButton: UIButton {
    init(weekday: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        setTitle(weekday.uppercased(), for: .normal)

        configureStyle()
        configureConstraints()

        isSelected = false

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.size.width / 2
    }

    private func configureStyle() {
        setTitleColor(.secondaryLabel, for: .normal)
        setTitleColor(.white, for: .highlighted)
        setTitleColor(.white, for: [.highlighted, .selected])
        setTitleColor(.white, for: .selected)

        titleLabel?.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .semibold)
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Metrics.toggleSize),
            heightAnchor.constraint(equalToConstant: Metrics.toggleSize),
        ])
    }

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
    }
}

private enum Metrics {
    static let toggleSize: CGFloat = 55.0
}
