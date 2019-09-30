import UIKit

protocol ViewMoreRowDelegate: class {
    func viewMoreSelectedForStatSection(_ statSection: StatSection)
}

class ViewMoreRow: UIView, NibLoadable, Accessible {

    // MARK: - Properties

    @IBOutlet weak var viewMoreLabel: UILabel!

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
        accessibilityTraits = .button
        accessibilityHint = NSLocalizedString("Tap for more detail.", comment: "Accessibility hint")
    }
}

// MARK: - Private Methods

private extension ViewMoreRow {

    func applyStyles() {
        backgroundColor = .listForeground
        viewMoreLabel.text = NSLocalizedString("View more", comment: "Label for viewing more stats.")
        viewMoreLabel.textColor = WPStyleGuide.Stats.actionTextColor
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

// MARK: - Analytics support

private extension StatSection {
    var analyticsViewMoreEvent: WPAnalyticsStat? {
        switch self {
        case .periodAuthors, .insightsCommentsAuthors:
            return .statsViewMoreTappedAuthors
        case .periodClicks:
            return .statsViewMoreTappedClicks
        case .periodOverviewComments:
            return .statsViewMoreTappedComments
        case .periodCountries:
            return .statsViewMoreTappedCountries
        case .insightsFollowerTotals, .insightsFollowersEmail, .insightsFollowersWordPress:
            return .statsViewMoreTappedFollowers
        case .periodPostsAndPages:
            return .statsViewMoreTappedPostsAndPages
        case .insightsPublicize:
            return .statsViewMoreTappedPublicize
        case .periodReferrers:
            return .statsViewMoreTappedReferrers
        case .periodSearchTerms:
            return .statsViewMoreTappedSearchTerms
        case .insightsTagsAndCategories:
            return .statsViewMoreTappedTagsAndCategories
        case .periodVideos:
            return .statsViewMoreTappedVideoPlays
        case .periodFileDownloads:
            return .statsViewMoreTappedFileDownloads
        default:
            return nil
        }
    }
}
