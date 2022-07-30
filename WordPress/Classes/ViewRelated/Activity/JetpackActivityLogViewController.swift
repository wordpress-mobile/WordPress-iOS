import UIKit
import Combine

class JetpackActivityLogViewController: BaseActivityListViewController {
    private let jetpackBannerView = JetpackBannerView()
    let scrollViewPublisher = PassthroughSubject<JPScrollViewDataDelegate, Never>()

    override init(site: JetpackSiteRef, store: ActivityStore, isFreeWPCom: Bool = false) {
        let activityListConfiguration = ActivityListConfiguration(
            identifier: "activity_log",
            title: NSLocalizedString("Activity", comment: "Title for the activity list"),
            loadingTitle: NSLocalizedString("Loading Activities...", comment: "Text displayed while loading the activity feed for a site"),
            noActivitiesTitle: NSLocalizedString("No activity yet", comment: "Title for the view when there aren't any Activities to display in the Activity Log"),
            noActivitiesSubtitle: NSLocalizedString("When you make changes to your site you'll be able to see your activity history here.", comment: "Text display when the view when there aren't any Activities to display in the Activity Log"),
            noMatchingTitle: NSLocalizedString("No matching events found.", comment: "Title for the view when there aren't any Activities to display in the Activity Log for a given filter."),
            noMatchingSubtitle: NSLocalizedString("Try adjusting your date range or activity type filters", comment: "Text display when the view when there aren't any Activities to display in the Activity Log for a given filter."),
            filterbarRangeButtonTapped: .activitylogFilterbarRangeButtonTapped,
            filterbarSelectRange: .activitylogFilterbarSelectRange,
            filterbarResetRange: .activitylogFilterbarResetRange,
            numberOfItemsPerPage: 20
        )

        super.init(site: site, store: store, configuration: activityListConfiguration, isFreeWPCom: isFreeWPCom)

        if JetpackBrandingVisibility.all.enabled {
            configureBanner()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        extendedLayoutIncludesOpaqueBars = true

        WPAnalytics.track(.activityLogViewed)
    }

    private func configureBanner() {
        containerStackView.addArrangedSubview(jetpackBannerView)

        NSLayoutConstraint.activate([
            jetpackBannerView.heightAnchor.constraint(greaterThanOrEqualToConstant: JetpackBannerView.minimumHeight)
        ])
        addTranslationObserver(jetpackBannerView)
    }
}

extension JetpackActivityLogViewController: JPScrollViewDelegate {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        scrollViewPublisher.send(scrollView)
    }
}
