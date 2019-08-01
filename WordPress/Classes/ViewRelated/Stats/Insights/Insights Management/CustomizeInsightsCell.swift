import UIKit

class CustomizeInsightsCell: UITableViewCell, NibLoadable {

    // MARK: - Properties

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var tryButton: UIButton!
    @IBOutlet weak var bottomSeparatorLine: UIView!

    private weak var insightsDelegate: SiteStatsInsightsDelegate?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(insightsDelegate: SiteStatsInsightsDelegate?) {
        self.insightsDelegate = insightsDelegate
        applyStyles()
    }

}

// MARK: - Private Extension

private extension CustomizeInsightsCell {

    // MARK: - Styles

    func applyStyles() {
        titleLabel.text = Labels.title
        contentLabel.text = Labels.content
        tryButton.setTitle(Labels.tryIt, for: .normal)
        dismissButton.setTitle(Labels.dismiss, for: .normal)

        Style.configureCell(self)
        Style.configureLabelAsCustomizeTitle(titleLabel)
        Style.configureLabelAsSummary(contentLabel)
        Style.configureAsCustomizeDismissButton(dismissButton)
        Style.configureAsCustomizeTryButton(tryButton)
        Style.configureViewAsSeparator(bottomSeparatorLine)
    }

    // MARK: - Button Handling

    @IBAction func didTapDismissButton(_ sender: UIButton) {
        insightsDelegate?.customizeDismissButtonTapped?()
    }

    @IBAction func didTapTryButton(_ sender: UIButton) {
        insightsDelegate?.customizeTryButtonTapped?()
    }

    struct Labels {
        static let title = NSLocalizedString("Customize your insights", comment: "Customize Insights title")
        static let content = NSLocalizedString("Create your own customized dashboard and choose what reports to see. Focus on the data you care most about.", comment: "Customize Insights description")
        static let tryIt = NSLocalizedString("Try it now", comment: "Customize Insights button title")
        static let dismiss = NSLocalizedString("Dismiss", comment: "Customize Insights button title")
    }
}
