import UIKit

class GrowAudienceCell: UITableViewCell, NibLoadable {

    @IBOutlet weak var viewCountLabel: UILabel!
    @IBOutlet weak var viewCountDescriptionLabel: UILabel!
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var actionButton: UIButton!

    private weak var insightsDelegate: SiteStatsInsightsDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    // MARK: - Configuration

    func configure(hintType: HintType,
                   allTimeViewsCount: Int,
                   insightsDelegate: SiteStatsInsightsDelegate?) {
        viewCountLabel.text = String(allTimeViewsCount)
        viewCountDescriptionLabel.text = Strings.getViewsCountDescription(viewsCount: allTimeViewsCount)
        tipLabel.text = Strings.tipTitle
        detailsLabel.text = hintType.detailsTitle
        iconView.image = hintType.image
        dismissButton.setTitle(Strings.dismissButtonTitle, for: .normal)
        actionButton.setTitle(hintType.actionButtonTitle, for: .normal)
        self.insightsDelegate = insightsDelegate
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

    // MARK: - IBAction

    @IBAction private func dismissButtonTapped(_ sender: UIButton) {
        insightsDelegate?.growAudienceDismissButtonTapped?()
    }

    @IBAction private func actionButtonTapped(_ sender: UIButton) {
        // TODO: address in a future PR
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

        enum BloggingReminders {
            static let detailsTitle =
                NSLocalizedString("Posting regularly can help build an audience. Reminders help keep you on track.",
                                  comment: "A detailed message to users about growing the audience for their site through blogging reminders.")
            static let actionButtonTitle =
                NSLocalizedString("Set up blogging reminders", comment: "Title for button that will open up the blogging reminders screen.")
        }

    }

}

extension GrowAudienceCell {

    enum HintType {
        case bloggingReminders

        var detailsTitle: String {
            switch self {
            case .bloggingReminders:
                return Strings.BloggingReminders.detailsTitle
            }
        }

        var actionButtonTitle: String {
            switch self {
            case .bloggingReminders:
                return Strings.BloggingReminders.actionButtonTitle
            }
        }

        var image: UIImage? {
            switch self {
            case .bloggingReminders:
                return UIImage(named: "grow-audience-illustration-blogging-reminders")
            }
        }
    }
}
