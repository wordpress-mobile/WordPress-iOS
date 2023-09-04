import UIKit

final class BlazeCampaignSingleStatView: UIView {

    // MARK: Public Variables

    var valueString: String? {
        didSet {
            self.numberLabel.text = valueString
        }
    }

    // MARK: Private Variables

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            numberLabel,
            titleLabel
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = Constants.mainStackViewSpacing
        return stackView
    }()

    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        label.textColor = .text
        label.isAccessibilityElement = false
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        label.textColor = .textSubtle
        label.isAccessibilityElement = false
        return label
    }()

    // MARK: Initializers

    convenience init(title: String) {
        self.init()
        self.numberLabel.text = Constants.emptyString
        self.titleLabel.text = title
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: Private Helpers

    private func setupViews() {
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)
    }
}

// MARK: Constants

private extension BlazeCampaignSingleStatView {

    enum Constants {
        static let mainStackViewSpacing = 4.0
        static let emptyString = "0"
    }
}
