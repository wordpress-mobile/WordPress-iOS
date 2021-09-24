import UIKit

class GrowAudienceCell: UITableViewCell, NibLoadable {

    @IBOutlet weak var viewCountStackView: UIStackView!
    @IBOutlet weak var viewCountLabel: UILabel!
    @IBOutlet weak var viewCountDescriptionLabel: UILabel!
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var actionButton: UIButton!

    private var hintType: HintType?

    private weak var insightsDelegate: SiteStatsInsightsDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    // MARK: - Configuration

    func configure(hintType: HintType,
                   allTimeViewsCount: Int,
                   insightsDelegate: SiteStatsInsightsDelegate?) {
        self.hintType = hintType
        self.insightsDelegate = insightsDelegate

        viewCountLabel.text = String(allTimeViewsCount)
        viewCountDescriptionLabel.text = Strings.getViewsCountDescription(viewsCount: allTimeViewsCount)
        iconView.image = hintType.image
        dismissButton.setTitle(Strings.dismissButtonTitle, for: .normal)

        updateView(isCompleted: false)
    }

    // MARK: - Styling

    private func applyStyles() {
        backgroundColor = .listForeground
        addBottomBorder(withColor: .divider)

        viewCountLabel.font = WPStyleGuide.fontForTextStyle(.title1)
        viewCountLabel.textColor = .textSubtle

        viewCountDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        viewCountDescriptionLabel.textColor = .textSubtle

        tipLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        tipLabel.textColor = .text
        tipLabel.numberOfLines = 0

        detailsLabel.font = WPStyleGuide.fontForTextStyle(.subheadline)
        detailsLabel.textColor = .text
        detailsLabel.numberOfLines = 0

        dismissButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body)

        actionButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .medium)
    }

    private func updateView(isCompleted: Bool) {
        guard let hintType = hintType else {
            return
        }

        viewCountStackView.isHidden = isCompleted
        iconView.isHidden = isCompleted

        tipLabel.text = hintType.getTipTitle(isCompleted)
        detailsLabel.text = hintType.getDetailsTitle(isCompleted)
        actionButton.setTitle(hintType.getActionButtonTitle(isCompleted), for: .normal)

        layoutIfNeeded()
    }

    // MARK: - IBAction

    @IBAction private func dismissButtonTapped(_ sender: UIButton) {
        insightsDelegate?.growAudienceDismissButtonTapped?()
    }

    @IBAction private func actionButtonTapped(_ sender: UIButton) {
        guard let hintType = hintType else {
            return
        }

        updateView(isCompleted: true)

        switch hintType {
        case .social:
            insightsDelegate?.growAudienceEnablePostSharingButtonTapped?()
        case .bloggingReminders:
            insightsDelegate?.growAudienceBloggingRemindersButtonTapped?()
        }

    }

    // MARK: - Localization

    private enum Strings {

        static let viewsCountDescriptionSingular =
            NSLocalizedString("View to your site so far", comment: "Description for view count. Singular.")

        static let viewsCountDescriptionPlural =
            NSLocalizedString("Views to your site so far", comment: "Description for view count. Singular.")

        static let tipTitle =
            NSLocalizedString("A tip to grow your audience",
                              comment: "A hint to users about growing the audience for their site, when their site doesn't have many views yet.")

        static let dismissButtonTitle =
            NSLocalizedString("Dismiss", comment: "Title for button that will dismiss the Grow Your Audience card.")

        static func getViewsCountDescription(viewsCount: Int) -> String {
            return viewsCount == 1 ? viewsCountDescriptionSingular : viewsCountDescriptionPlural
        }

        enum Social {
            static let detailsTitle =
                NSLocalizedString("Automatically share new posts to your social media to start bringing that audience over to your site.",
                                  comment: "A detailed message to users about growing the audience for their site through enabling post sharing.")

            static let actionButtonTitle =
                NSLocalizedString("Enable post sharing", comment: "Title for button that will open up the social media Sharing screen.")

            static let completedTipTitle =
                NSLocalizedString("Sharing is set up!",
                                  comment: "A hint to users that they've set up post sharing.")

            static let completedDetailsTitle =
                NSLocalizedString("When you publish your next post it will be automatically shared to your connected networks.",
                                  comment: "A detailed message to users indicating that they've set up post sharing.")

            static let completedActionButtonTitle =
                NSLocalizedString("Connect more networks", comment: "Title for button that will open up the social media Sharing screen.")
        }

        enum BloggingReminders {
            static let detailsTitle =
                NSLocalizedString("Posting regularly can help build an audience. Reminders help keep you on track.",
                                  comment: "A detailed message to users about growing the audience for their site through blogging reminders.")

            static let actionButtonTitle =
                NSLocalizedString("Set up blogging reminders", comment: "Title for button that will open up the blogging reminders screen.")

            static let completedTipTitle =
                NSLocalizedString("You set up blogging reminders",
                                  comment: "A hint to users that they've set up blogging reminders.")

            static let completedDetailsTitle =
                NSLocalizedString("Keep blogging and check back to see visitors arriving at your site.",
                                  comment: "A detailed message to users indicating that they've set up blogging reminders.")

            static let completedActionButtonTitle =
                NSLocalizedString("Edit reminders", comment: "Title for button that will open up the blogging reminders screen.")
        }

    }

}

extension GrowAudienceCell {

    enum HintType {

        case social
        case bloggingReminders

        func getTipTitle(_ isCompleted: Bool) -> String {
            return isCompleted ? completedTipTitle : Strings.tipTitle
        }

        func getDetailsTitle(_ isCompleted: Bool) -> String {
            return isCompleted ? completedDetailsTitle : detailsTitle
        }

        func getActionButtonTitle(_ isCompleted: Bool) -> String {
            return isCompleted ? completedActionButtonTitle : actionButtonTitle
        }

        var completedTipTitle: String {
            switch self {
            case .social:
                return Strings.Social.completedTipTitle
            case .bloggingReminders:
                return Strings.BloggingReminders.completedTipTitle
            }
        }

        var detailsTitle: String {
            switch self {
            case .social:
                return Strings.Social.detailsTitle
            case .bloggingReminders:
                return Strings.BloggingReminders.detailsTitle
            }
        }

        var completedDetailsTitle: String {
            switch self {
            case .social:
                return Strings.Social.completedDetailsTitle
            case .bloggingReminders:
                return Strings.BloggingReminders.completedDetailsTitle
            }
        }

        var actionButtonTitle: String {
            switch self {
            case .social:
                return Strings.Social.actionButtonTitle
            case .bloggingReminders:
                return Strings.BloggingReminders.actionButtonTitle
            }
        }

        var completedActionButtonTitle: String {
            switch self {
            case .social:
                return Strings.Social.completedActionButtonTitle
            case .bloggingReminders:
                return Strings.BloggingReminders.completedActionButtonTitle
            }
        }

        var image: UIImage? {
            switch self {
            case .social:
                return UIImage(named: "grow-audience-illustration-social")
            case .bloggingReminders:
                return UIImage(named: "grow-audience-illustration-blogging-reminders")
            }
        }
    }
}
