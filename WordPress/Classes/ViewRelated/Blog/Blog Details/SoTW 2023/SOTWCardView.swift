/// A seasonal card view shown in the WordPress app to promote State of the Word 2023.
///
class SotWCardView: UIView {

    // MARK: - Views

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.setText(Strings.body)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var watchNowButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.button, for: .normal)
        button.setTitleColor(.primary, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(onButtonTap), for: .touchUpInside)
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [bodyLabel, watchNowButton])
        stackView.axis = .vertical
        stackView.spacing = 8.0
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .init(top: 0, leading: 16, bottom: 4, trailing: 16)
        return stackView
    }()

    private lazy var cardFrameView: BlogDashboardCardFrameView = {
        let frameView = BlogDashboardCardFrameView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.setTitle(Strings.title)
        frameView.onEllipsisButtonTap = {}
        frameView.ellipsisButton.showsMenuAsPrimaryAction = true
        frameView.ellipsisButton.menu = nil // TODO.
        frameView.add(subview: contentStackView)

        return frameView
    }()

    // MARK: Initializers

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods

    private func setupView() {
        addSubview(cardFrameView)
        pinSubviewToAllEdges(cardFrameView)
    }

}

// MARK: - Private Helpers

private extension SotWCardView {

    @objc func onButtonTap() {
        // TODO: Redirect to livestream landing page.
    }

    struct Strings {
        static let title = "State of the Word 2023"
        static let body = "Check out WordPress co-founder Matt Mullenweg's annual keynote to stay on top of what's coming in 2024 and beyond."
        static let button = "Watch now"
    }
}

// MARK: - UITableViewCell Wrapper

class SotWTableViewCell: UITableViewCell {

    private lazy var cardView: SotWCardView = {
        let cardView = SotWCardView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        return cardView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setText("Hello, world!")
        contentView.addSubview(cardView)
        contentView.pinSubviewToAllEdges(cardView, priority: .defaultHigh)
    }

}

// MARK: - BlogDetailsViewController Registration

extension BlogDetailsViewController {

    @objc func sotw2023SectionViewModel() -> BlogDetailsSection {
        let row = BlogDetailsRow()
        row.callback = {}
        let section = BlogDetailsSection(title: nil,
                                         rows: [row],
                                         footerTitle: nil,
                                         category: .sotW2023Card)
        return section
    }

    @objc func shouldShowSotW2023Card() -> Bool {
        guard AppConfiguration.isWordPress && RemoteFeatureFlag.wordPressSotWCard.enabled() else {
            return false
        }

        // ensure that the device language is in English.
        let usesEnglish = WordPressComLanguageDatabase().deviceLanguageSlugString() == "en"

        // ensure that the card is not displayed before Dec. 11, 2023 where the event takes place.
        let dateComponents = Date().dateAndTimeComponents()
        let isPostEvent = {
            guard let day = dateComponents.day,
                  let month = dateComponents.month,
                  let year = dateComponents.year,
                  year < 2024 else {
                return true
            }
            return month == 12 && day > 11
        }()

        return usesEnglish && isPostEvent
    }

}
