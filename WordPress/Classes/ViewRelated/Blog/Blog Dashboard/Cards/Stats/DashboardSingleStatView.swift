import UIKit

final class DashboardSingleStatView: UIView {

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
        label.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .bold)
        label.textColor = .text
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.subheadline)
        label.textColor = .textSubtle
        return label
    }()

    // MARK: Initializers

    convenience init(countString: String, title: String) {
        self.init()
        self.numberLabel.text = countString
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
    }
}
