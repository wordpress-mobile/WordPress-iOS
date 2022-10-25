import UIKit

final class JetpackLandingScreenView: UIView {

    // MARK: - Properties

    private var labels: [UILabel] = []

    private var compactConstraints = [NSLayoutConstraint]()
    private var regularConstraints = [NSLayoutConstraint]()

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        // Setup view
        let prompts = Constants.prompts
        let labels = (0..<prompts.count * 2).map {
            Self.label(atIndex: $0, text: prompts[$0 % prompts.count], traits: self.traitCollection)
        }
        let stackView = UIStackView(arrangedSubviews: labels)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = Constants.interitemSpacing
        self.labels = labels
        self.addSubview(stackView)

        // Setup constraints
        let insets = Constants.insets
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
        self.compactConstraints = [
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right)
        ]
        self.regularConstraints = [
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.maxWidth),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ]
    }

    // MARK: - Layout Lifecycle

    override func updateConstraints() {
        super.updateConstraints()
        let isCompactSizeClass = traitCollection.horizontalSizeClass == .compact
        self.compactConstraints.forEach { $0.isActive = isCompactSizeClass }
        self.regularConstraints.forEach { $0.isActive = !isCompactSizeClass }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.setNeedsUpdateConstraints()
        self.updateLabelsTextAttributes()
    }

    // MARK: - Label Factory

    private static func label(atIndex index: Int, text: String?, traits: UITraitCollection) -> UILabel {
        let label = UILabel()
        label.accessibilityElementsHidden = true
        label.numberOfLines = 0
        label.attributedText = Self.attributedTextForLabel(atIndex: index, text: text, traits: traits)
        return label
    }

    // MARK: - Label Attributes

    private static func attributedTextForLabel(atIndex index: Int, text: String?, traits: UITraitCollection) -> NSAttributedString? {
        guard let text else {
            return nil
        }
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes(attributesForLabel(atIndex: index, traits: traits), range: NSMakeRange(0, text.utf16.count))
        return attributedString
    }

    private static func attributesForLabel(atIndex index: Int, traits: UITraitCollection) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = Constants.lineHeightMultiple
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: index % 2 == 0 ? Constants.evenColor : Constants.oddColor,
            .font: Constants.font(for: traits.horizontalSizeClass)
        ]
        return attributes
    }

    private func updateLabelsTextAttributes() {
        for (index, label) in labels.enumerated() {
            label.attributedText = Self.attributedTextForLabel(atIndex: index, text: label.text, traits: traitCollection)
        }
    }

    // MARK: - Constants

    private struct Constants {
        static let prompts = JetpackPromptsConfiguration.Constants.basePrompts
        static let evenColor = JetpackPromptsConfiguration.Constants.evenColor
        static let oddColor = JetpackPromptsConfiguration.Constants.oddColor

        static let interitemSpacing: CGFloat = 8
        static let insets = UIEdgeInsets(top: Self.interitemSpacing, left: 16, bottom: 0, right: 16)
        static let maxWidth: CGFloat = 579

        static let lineHeightMultiple: CGFloat = 0.8

        static func font(for size: UIUserInterfaceSizeClass) -> UIFont {
            let fontSize: CGFloat = size == .compact ? 40 : 70
            return UIFont.systemFont(ofSize: fontSize, weight: .bold)
        }
    }
}
