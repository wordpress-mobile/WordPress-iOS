import UIKit

final class DashboardSingleStatView: UIView {

    // MARK: Public Variables

    var countString: String? {
        didSet {
            self.numberLabel.text = countString
        }
    }

    // MARK: Private Variables

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            numberLabel
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
        label.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .bold)
        label.textColor = .text
        label.isAccessibilityElement = false
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.subheadline)
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

private extension DashboardSingleStatView {

    enum Constants {
        static let mainStackViewSpacing = 2.0
        static let emptyString = "0"
    }
}
