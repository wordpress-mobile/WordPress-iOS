import UIKit

class DashboardPageCell: UITableViewCell, Reusable {

    // MARK: Variables

    // MARK: Views

    lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.mainStackViewSpacing
        stackView.directionalLayoutMargins = Metrics.mainStackViewLayoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addBottomBorder(withColor: Colors.separatorColor, leadingMargin: Metrics.separatorLeadingMargin)
        stackView.addArrangedSubviews([titleLabel]) // TODO: Add views
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .bold)
        label.numberOfLines = 1
        label.textAlignment = .natural
        label.textColor = .text
        return label
    }()

    // MARK: Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: View Lifecycle

    override func prepareForReuse() {
        // TODO: Implement this if needed
    }

    // MARK: Public Functions

    func configure(using page: Page) {
        titleLabel.text = page.titleForDisplay()
    }

    // MARK: Helpers

    private func commonInit() {
        setupViews()
    }

    private func setupViews() {
        contentView.addSubview(mainStackView)
        contentView.pinSubviewToAllEdges(mainStackView)
    }

}

private extension DashboardPageCell {
    enum Metrics {
        static let mainStackViewSpacing: CGFloat = 6
        static let mainStackViewLayoutMargins: NSDirectionalEdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
        static let separatorLeadingMargin: CGFloat = 16
    }
    
    enum Colors {
        static let separatorColor = UIColor(red: 0.235, green: 0.235, blue: 0.263, alpha: 0.36)
    }
}
