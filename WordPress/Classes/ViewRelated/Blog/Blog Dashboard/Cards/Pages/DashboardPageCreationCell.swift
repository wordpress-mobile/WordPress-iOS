import UIKit

class DashboardPageCreationCell: UITableViewCell, Reusable {

    // MARK: Views

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Metrics.mainStackViewSpacing
        stackView.directionalLayoutMargins = Metrics.mainStackViewLayoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubviews([labelsStackView])
        return stackView
    }()

    private lazy var labelsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.labelsStackViewSpacing
        stackView.directionalLayoutMargins = Metrics.labelsStackViewLayoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubviews([createPageButton, descriptionLabel])
        return stackView
    }()

    private lazy var createPageButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(createPageButtonTapped), for: .touchUpInside)
        let font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .bold)

        if #available(iOS 15.0, *) {
            var buttonConfig: UIButton.Configuration = .plain()
            buttonConfig.contentInsets = Metrics.createPageButtonContentInsets
            buttonConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ incoming in
                var outgoing = incoming
                outgoing.font = font
                return outgoing
            })
            button.configuration = buttonConfig
        } else {
            button.titleLabel?.font = font
            button.contentEdgeInsets = Metrics.createPageButtonContentEdgeInsets
            button.flipInsetsForRightToLeftLayoutDirection()
        }

        // TODO: Remove this when configure() is implemented
        button.setTitle(Strings.createPageButtonText, for: .normal)
        return button
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = WPStyleGuide.regularTextFont()
        label.textColor = .secondaryLabel
        label.text = Strings.descriptionLabelText
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

    // MARK: Public Functions

    func configure(expanded: Bool, hasPages: Bool) {
        // TODO: Configure cell bases on passed values
    }

    // MARK: Helpers

    private func commonInit() {
        setupViews()
        applyStyle()
    }

    private func applyStyle() {
        backgroundColor = .clear
    }

    private func setupViews() {
        contentView.addSubview(mainStackView)
        contentView.pinSubviewToAllEdges(mainStackView)
    }

    // MARK: Actions

    @objc func createPageButtonTapped() {
        // TODO: To be implemented
    }
}

private extension DashboardPageCreationCell {
    enum Metrics {
        static let mainStackViewSpacing: CGFloat = 16
        static let mainStackViewLayoutMargins: NSDirectionalEdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        static let labelsStackViewSpacing: CGFloat = 2
        static let labelsStackViewLayoutMargins: NSDirectionalEdgeInsets = .init(top: 16, leading: 0, bottom: 16, trailing: 0)
        static let createPageButtonContentInsets = NSDirectionalEdgeInsets.zero
        static let createPageButtonContentEdgeInsets = UIEdgeInsets.zero
    }

    enum Colors {
    }

    enum Strings {
        static let descriptionLabelText = NSLocalizedString("dashboardCard.pages.create.description",
                                                            value: "Start with bespoke, mobile friendly layouts.",
                                                            comment: "Title of a label that encourages the user to create a new page.")
        static let createPageButtonText = NSLocalizedString("dashboardCard.pages.create.button.title",
                                                            value: "Create another page",
                                                            comment: "Title of a button that starts the page creation flow.")
    }
}
