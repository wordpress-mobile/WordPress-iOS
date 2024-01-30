import UIKit

protocol ViewMoreRowDelegate: AnyObject {
    func viewMoreSelectedForStatSection(_ statSection: StatSection)
}

class ViewMoreRow: UIView, NibLoadable, Accessible {

    // MARK: - Properties

    @IBOutlet weak var viewMoreLabel: UILabel!
    @IBOutlet weak var disclosureImageView: UIImageView!

    private var statSection: StatSection?
    private weak var delegate: ViewMoreRowDelegate?

    // MARK: - Configure

    func configure(statSection: StatSection?, delegate: ViewMoreRowDelegate?) {
        self.statSection = statSection
        self.delegate = delegate
        applyStyles()
        prepareForVoiceOver()
    }

    func prepareForVoiceOver() {
        isAccessibilityElement = true

        accessibilityLabel = viewMoreLabel.text
        accessibilityHint = NSLocalizedString("Tap to view more details.", comment: "Accessibility hint for a button that opens a new view with more details.")
        accessibilityTraits = .button
    }
}

// MARK: - Private Methods

private extension ViewMoreRow {

    func applyStyles() {
        backgroundColor = .listForeground
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more stats.")
        viewMoreLabel.textColor = WPStyleGuide.Stats.actionTextColor
        if statSection == .insightsFollowersWordPress || statSection == .insightsFollowersEmail {
            disclosureImageView.isHidden = true
        }
    }

    @IBAction func didTapViewMoreButton(_ sender: UIButton) {
        guard let statSection = statSection else {
            return
        }

        captureAnalyticsEventsFor(statSection)
        delegate?.viewMoreSelectedForStatSection(statSection)
    }

    func captureAnalyticsEventsFor(_ statSection: StatSection) {
        let legacyEvent: WPAnalyticsStat = .statsViewAllAccessed
        captureAnalyticsEvent(legacyEvent)

        if let modernEvent = statSection.analyticsViewMoreEvent {
            captureAnalyticsEvent(modernEvent)
        }
    }

    func captureAnalyticsEvent(_ event: WPAnalyticsStat) {
        if let blogIdentifier = SiteStatsInformation.sharedInstance.siteID {
            WPAppAnalytics.track(event, withBlogID: blogIdentifier)
        } else {
            WPAppAnalytics.track(event)
        }
    }
}
