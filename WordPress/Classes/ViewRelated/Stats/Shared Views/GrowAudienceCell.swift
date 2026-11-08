import UIKit
import WordPressShared

class GrowAudienceCell: UITableViewCell {

    private let viewCountStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .firstBaseline
        stackView.spacing = 8
        return stackView
    }()
    private let viewCountLabel = makeLabel(textStyle: .title1)
    private let viewCountDescriptionLabel: UILabel = {
        let label = makeLabel(text: "Views to your site so far", textStyle: .body)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()
    private let tipLabel: UILabel = {
        let label = makeLabel(textStyle: .title3, numberOfLines: 0)
        label.setContentHuggingPriority(UILayoutPriority(252), for: .vertical)
        return label
    }()
    private let detailsLabel = makeLabel(textStyle: .subheadline, numberOfLines: 0)
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return imageView
    }()
    private let dismissButton = makeButton()
    private let actionButton = makeButton()

    private var hintType: HintType?

    private weak var insightsDelegate: SiteStatsInsightsDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.clipsToBounds = true
        contentView.contentMode = .center
        setUpViews()
        applyStyles()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        [viewCountLabel, viewCountDescriptionLabel].forEach(viewCountStackView.addArrangedSubview)

        let tipStackView = UIStackView(arrangedSubviews: [tipLabel, detailsLabel])
        tipStackView.axis = .vertical
        tipStackView.spacing = 8

        let hintStackView = UIStackView(arrangedSubviews: [tipStackView, iconView])
        hintStackView.alignment = .top
        hintStackView.spacing = 24

        let contentStackView = UIStackView(arrangedSubviews: [viewCountStackView, hintStackView])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 16

        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        let buttonsStackView = UIStackView(arrangedSubviews: [dismissButton, actionButton])
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.distribution = .equalSpacing
        buttonsStackView.spacing = 16

        contentView.addSubview(contentStackView)
        contentView.addSubview(buttonsStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 16),

            viewCountLabel.topAnchor.constraint(equalTo: viewCountStackView.topAnchor),
            viewCountLabel.centerYAnchor.constraint(equalTo: viewCountStackView.centerYAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 88),
            iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),

            buttonsStackView.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 32),
            buttonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonsStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            contentView.bottomAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 16),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 30),
            actionButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private static func makeLabel(
        text: String = "Label",
        textStyle: UIFont.TextStyle,
        numberOfLines: Int = 1
    ) -> UILabel {
        let label = UILabel.makeStatsLabel(text: text, textStyle: textStyle, numberOfLines: numberOfLines)
        label.adjustsFontForContentSizeCategory = false
        return label
    }

    private static func makeButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Button", for: .normal)
        return button
    }

    // MARK: - Configuration

    func configure(
        hintType: HintType,
        allTimeViewsCount: Int,
        isNudgeCompleted: Bool,
        insightsDelegate: SiteStatsInsightsDelegate?
    ) {
        self.hintType = hintType
        self.insightsDelegate = insightsDelegate

        viewCountLabel.text = String(allTimeViewsCount)
        viewCountDescriptionLabel.text = Strings.getViewsCountDescription(viewsCount: allTimeViewsCount)
        iconView.image = hintType.image
        dismissButton.setTitle(Strings.dismissButtonTitle, for: .normal)

        updateView(isCompleted: isNudgeCompleted)

        prepareForVoiceOver(
            hintType: hintType,
            allTimeViewsCount: allTimeViewsCount,
            isNudgeCompleted: isNudgeCompleted
        )
    }

    // MARK: - A11y

    func prepareForVoiceOver(hintType: HintType, allTimeViewsCount: Int, isNudgeCompleted: Bool) {

        viewCountStackView.isAccessibilityElement = true
        viewCountStackView.accessibilityTraits = .staticText
        viewCountStackView.accessibilityLabel = Strings.getViewCountSummary(viewsCount: allTimeViewsCount)

        tipLabel.isAccessibilityElement = true
        tipLabel.accessibilityTraits = .staticText
        tipLabel.accessibilityLabel = hintType.getTipTitle((isNudgeCompleted))

        detailsLabel.isAccessibilityElement = true
        detailsLabel.accessibilityTraits = .staticText
        detailsLabel.accessibilityLabel = hintType.getDetailsTitle(isNudgeCompleted)

        dismissButton.accessibilityLabel = Strings.dismissButtonTitle

        actionButton.accessibilityLabel = hintType.getActionButtonTitle(isNudgeCompleted)

        accessibilityElements = [
            viewCountStackView,
            tipLabel,
            detailsLabel,
            dismissButton,
            actionButton
        ]
        .compactMap { $0 }
    }

    // MARK: - Styling

    private func applyStyles() {
        selectionStyle = .none
        backgroundColor = .secondarySystemGroupedBackground

        viewCountLabel.font = WPStyleGuide.fontForTextStyle(.title1)
        viewCountLabel.textColor = .secondaryLabel

        viewCountDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        viewCountDescriptionLabel.textColor = .secondaryLabel

        tipLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        tipLabel.textColor = .label
        tipLabel.numberOfLines = 0

        detailsLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        detailsLabel.textColor = .label
        detailsLabel.numberOfLines = 0

        dismissButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body)

        actionButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
    }

    private func updateView(isCompleted: Bool) {
        guard let hintType else {
            return
        }

        viewCountStackView.isHidden = isCompleted
        iconView.isHidden = isCompleted

        tipLabel.text = hintType.getTipTitle(isCompleted)
        detailsLabel.text = hintType.getDetailsTitle(isCompleted)
        actionButton.setTitle(hintType.getActionButtonTitle(isCompleted), for: .normal)

        layoutIfNeeded()
    }

    // MARK: - Actions

    @objc private func dismissButtonTapped(_ sender: UIButton) {
        guard let hintType else {
            return
        }
        insightsDelegate?.growAudienceDismissButtonTapped?(hintType)
    }

    @objc private func actionButtonTapped(_ sender: UIButton) {
        guard let hintType else {
            return
        }

        switch hintType {
        case .social:
            insightsDelegate?.growAudienceEnablePostSharingButtonTapped?()
        case .bloggingReminders:
            insightsDelegate?.growAudienceBloggingRemindersButtonTapped?()
        case .readerDiscover:
            insightsDelegate?.growAudienceReaderDiscoverButtonTapped?()
        }
    }

    // MARK: - Localization

    private enum Strings {

        static let viewsCountDescriptionSingular = NSLocalizedString(
            "growAudienceCell.viewsCount.singular",
            value: "View to your site so far",
            comment: "Description for view count. Singular."
        )

        static let viewsCountDescriptionPlural = NSLocalizedString(
            "growAudienceCell.viewsCount.plural",
            value: "Views to your site so far",
            comment: "Description for view count. Singular."
        )

        static let tipTitle = NSLocalizedString(
            "growAudienceCell.tip",
            value: "A tip to grow your audience",
            comment:
                "A hint to users about growing the audience for their site, when their site doesn't have many views yet."
        )

        static let dismissButtonTitle = NSLocalizedString(
            "growAudienceCell.dismiss",
            value: "Dismiss",
            comment: "Title for button that will dismiss the Grow Your Audience card."
        )

        static func getViewsCountDescription(viewsCount: Int) -> String {
            viewsCount == 1 ? viewsCountDescriptionSingular : viewsCountDescriptionPlural
        }

        static func getViewCountSummary(viewsCount: Int) -> String {
            let description = getViewsCountDescription(viewsCount: viewsCount)
            return "\(viewsCount) \(description)"
        }

        enum Social {
            static let detailsTitle = NSLocalizedString(
                "growAudienceCell.social.title",
                value:
                    "Automatically share new posts to your social media to start bringing that audience over to your site.",
                comment:
                    "A detailed message to users about growing the audience for their site through enabling post sharing."
            )

            static let actionButtonTitle = NSLocalizedString(
                "growAudienceCell.social.actionButton",
                value: "Enable post sharing",
                comment: "Title for button that will open up the social media Sharing screen."
            )

            static let completedTipTitle = NSLocalizedString(
                "growAudienceCell.social.completed.title",
                value: "Sharing is set up!",
                comment: "A hint to users that they've set up post sharing."
            )

            static let completedDetailsTitle = NSLocalizedString(
                "growAudienceCell.social.completed.details",
                value: "When you publish your next post it will be automatically shared to your connected networks.",
                comment: "A detailed message to users indicating that they've set up post sharing."
            )

            static let completedActionButtonTitle = NSLocalizedString(
                "growAudienceCell.social.completed.button",
                value: "Connect more networks",
                comment: "Title for button that will open up the social media Sharing screen."
            )
        }

        enum BloggingReminders {
            static let detailsTitle = NSLocalizedString(
                "growAudienceCell.bloggingReminders.details",
                value: "Posting regularly can help build an audience. Reminders help keep you on track.",
                comment:
                    "A detailed message to users about growing the audience for their site through blogging reminders."
            )

            static let actionButtonTitle = NSLocalizedString(
                "growAudienceCell.bloggingReminders.actionButton",
                value: "Set up blogging reminders",
                comment: "Title for button that will open up the blogging reminders screen."
            )

            static let completedTipTitle = NSLocalizedString(
                "growAudienceCell.bloggingReminders.completed.tip",
                value: "You set up blogging reminders",
                comment: "A hint to users that they've set up blogging reminders."
            )

            static let completedDetailsTitle = NSLocalizedString(
                "growAudienceCell.bloggingReminders.completed.details",
                value: "Keep blogging and check back to see visitors arriving at your site.",
                comment: "A detailed message to users indicating that they've set up blogging reminders."
            )

            static let completedActionButtonTitle = NSLocalizedString(
                "growAudienceCell.bloggingReminders.completed.actionButton",
                value: "Edit reminders",
                comment: "Title for button that will open up the blogging reminders screen."
            )
        }

        enum ReaderDiscover {
            static let detailsTitle = NSLocalizedString(
                "growAudienceCell.readerDiscover.details",
                value: "Connect with other bloggers by subscribing, liking and commenting on their posts.",
                comment:
                    "A detailed message to users about growing the audience for their site through reader discover."
            )

            static let actionButtonTitle = NSLocalizedString(
                "growAudienceCell.readerDiscover.actionButton",
                value: "Discover blogs to subscribe",
                comment: "Title for button that will open up the subscribe topics screen."
            )

            static let completedTipTitle = NSLocalizedString(
                "growAudienceCell.readerDiscover.completed.tip",
                value: "You've connected with other blogs",
                comment: "A hint to users that they've set up reader discover."
            )

            static let completedDetailsTitle = NSLocalizedString(
                "growAudienceCell.readerDiscover.completed.details",
                value:
                    "Keep going! Liking and commenting is a good way to build a network. Go to Reader to find more posts.",
                comment: "A detailed message to users indicating that they've set up reader discover."
            )

            static let completedActionButtonTitle = NSLocalizedString(
                "growAudienceCell.readerDiscover.completed.action",
                value: "Do it again",
                comment: "Title for button that will open up the follow topics screen."
            )
        }
    }
}

extension GrowAudienceCell {

    @objc enum HintType: Int, SiteStatsPinnable {

        case social
        case bloggingReminders
        case readerDiscover

        func getTipTitle(_ isCompleted: Bool) -> String {
            isCompleted ? completedTipTitle : Strings.tipTitle
        }

        func getDetailsTitle(_ isCompleted: Bool) -> String {
            isCompleted ? completedDetailsTitle : detailsTitle
        }

        func getActionButtonTitle(_ isCompleted: Bool) -> String {
            isCompleted ? completedActionButtonTitle : actionButtonTitle
        }

        var completedTipTitle: String {
            switch self {
            case .social:
                return Strings.Social.completedTipTitle
            case .bloggingReminders:
                return Strings.BloggingReminders.completedTipTitle
            case .readerDiscover:
                return Strings.ReaderDiscover.completedTipTitle
            }
        }

        var detailsTitle: String {
            switch self {
            case .social:
                return Strings.Social.detailsTitle
            case .bloggingReminders:
                return Strings.BloggingReminders.detailsTitle
            case .readerDiscover:
                return Strings.ReaderDiscover.detailsTitle
            }
        }

        var completedDetailsTitle: String {
            switch self {
            case .social:
                return Strings.Social.completedDetailsTitle
            case .bloggingReminders:
                return Strings.BloggingReminders.completedDetailsTitle
            case .readerDiscover:
                return Strings.ReaderDiscover.completedDetailsTitle
            }
        }

        var actionButtonTitle: String {
            switch self {
            case .social:
                return Strings.Social.actionButtonTitle
            case .bloggingReminders:
                return Strings.BloggingReminders.actionButtonTitle
            case .readerDiscover:
                return Strings.ReaderDiscover.actionButtonTitle
            }
        }

        var completedActionButtonTitle: String {
            switch self {
            case .social:
                return Strings.Social.completedActionButtonTitle
            case .bloggingReminders:
                return Strings.BloggingReminders.completedActionButtonTitle
            case .readerDiscover:
                return Strings.ReaderDiscover.completedActionButtonTitle
            }
        }

        var image: UIImage? {
            switch self {
            case .social:
                return UIImage(named: "grow-audience-illustration-social")
            case .bloggingReminders:
                return UIImage(named: "grow-audience-illustration-blogging-reminders")
            case .readerDiscover:
                return UIImage(named: "grow-audience-illustration-reader")
            }
        }

        var userDefaultsKey: String {
            switch self {
            case .social:
                return "social"
            case .bloggingReminders:
                return "bloggingReminders"
            case .readerDiscover:
                return "readerDiscover"
            }
        }
    }
}
