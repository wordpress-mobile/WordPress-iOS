
import UIKit

// MARK: StatsChartLegendView

class StatsChartLegendView: UIView {

    // MARK: Properties

    private struct Constants {
        static let capsuleCornerRadius  = CGFloat(2)
        static let capsuleHeight        = CGFloat(8)
        static let capsuleWidth         = CGFloat(16)
        static let intrinsicHeight      = CGFloat(16)
        static let intrinsicWidth       = CGFloat(72)
        static let spacing              = CGFloat(8)
    }

    private let color: UIColor
    private let title: String

    private let capsule: UIView
    private let label: UILabel

    // MARK: StatsLegendView

    init(color: UIColor, title: String) {
        self.color = color
        self.title = title

        self.capsule = {
            let view = UIView()

            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = color
            view.layer.cornerRadius = Constants.capsuleCornerRadius

            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: Constants.capsuleWidth),
                view.heightAnchor.constraint(equalToConstant: Constants.capsuleHeight)
            ])

            return view
        }()

        self.label = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0
            label.preferredMaxLayoutWidth = Constants.intrinsicWidth - Constants.capsuleWidth

            label.font = WPStyleGuide.fixedFont(for: .caption2)
            label.textColor = .neutral(.shade50)
            label.text = title

            label.sizeToFit()

            return label
        }()

        super.init(frame: .zero)

        initialize()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Constants.intrinsicWidth, height: Constants.intrinsicHeight)
    }

    // MARK: Private behavior

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = WPStyleGuide.Stats.cellBackgroundColor

        addSubview(capsule)
        addSubview(label)

        NSLayoutConstraint.activate([
            capsule.leadingAnchor.constraint(equalTo: leadingAnchor),
            capsule.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: capsule.trailingAnchor, constant: Constants.spacing),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])

        prepareForVoiceOver()
    }
}

// MARK: - Accessible

extension StatsChartLegendView: Accessible {
    func prepareForVoiceOver() {
        // This is the default state for non-control views. We set it explicitly for clarity,
        // choosing instead to rely on the default a11y support offered by Charts framework.
        isAccessibilityElement = false
    }
}
