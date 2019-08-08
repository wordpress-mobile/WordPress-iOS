import UIKit

class CustomizeInsightsCell: UITableViewCell, NibLoadable, Accessible {

    // MARK: - Properties

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var contentLabel: UILabel!
    @IBOutlet private var dismissButton: UIButton!
    @IBOutlet private var tryButton: UIButton!
    @IBOutlet private var bottomSeparatorLine: UIView!

    private weak var insightsDelegate: SiteStatsInsightsDelegate?
    private typealias Style = WPStyleGuide.Stats

    // MARK: - Configure

    func configure(insightsDelegate: SiteStatsInsightsDelegate?) {
        self.insightsDelegate = insightsDelegate
        applyStyles()
        prepareForVoiceOver()
    }

    func prepareForVoiceOver() {
        titleLabel.isAccessibilityElement = true
        titleLabel.accessibilityTraits = .staticText
        titleLabel.accessibilityLabel = Labels.title

        contentLabel.isAccessibilityElement = true
        contentLabel.accessibilityTraits = .staticText
        contentLabel.accessibilityLabel = Labels.content

        dismissButton.accessibilityLabel = Labels.dismiss
        dismissButton.accessibilityHint = Labels.dismissHint

        tryButton.accessibilityLabel = Labels.tryIt
        tryButton.accessibilityHint = Labels.tryItHint
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
        WPAppAnalytics.track(.statsItemTappedInsightsCustomizeDismiss)
        insightsDelegate?.customizeDismissButtonTapped?()
    }

    @IBAction func didTapTryButton(_ sender: UIButton) {
        WPAppAnalytics.track(.statsItemTappedInsightsCustomizeTry)
        insightsDelegate?.customizeTryButtonTapped?()
    }

    // MARK: - Constants

    struct Labels {
        static let title = NSLocalizedString("Customize your insights", comment: "Customize Insights title")
        static let content = NSLocalizedString("Create your own customized dashboard and choose what reports to see. Focus on the data you care most about.", comment: "Customize Insights description")
        static let tryIt = NSLocalizedString("Try it now", comment: "Customize Insights button title")
        static let dismiss = NSLocalizedString("Dismiss", comment: "Customize Insights button title")
        static let dismissHint = NSLocalizedString("Tap to dismiss this card", comment: "Accessibility hint")
        static let tryItHint = NSLocalizedString("Tap to customize insights", comment: "Accessibility hint")
    }

}
