import UIKit

class JetpackActivityLogViewController: BaseActivityListViewController {
    override init(site: JetpackSiteRef, store: ActivityStore, isFreeWPCom: Bool = false) {
        let activityListConfiguration = ActivityListConfiguration(
            identifier: "activity_log",
            title: AppLocalizedString("Activity", comment: "Title for the activity list"),
            loadingTitle: AppLocalizedString("Loading Activities...", comment: "Text displayed while loading the activity feed for a site"),
            noActivitiesTitle: AppLocalizedString("No activity yet", comment: "Title for the view when there aren't any Activities to display in the Activity Log"),
            noActivitiesSubtitle: AppLocalizedString("When you make changes to your site you'll be able to see your activity history here.", comment: "Text display when the view when there aren't any Activities to display in the Activity Log"),
            noMatchingTitle: AppLocalizedString("No matching events found.", comment: "Title for the view when there aren't any Activities to display in the Activity Log for a given filter."),
            noMatchingSubtitle: AppLocalizedString("Try adjusting your date range or activity type filters", comment: "Text display when the view when there aren't any Activities to display in the Activity Log for a given filter."),
            filterbarRangeButtonTapped: .activitylogFilterbarRangeButtonTapped,
            filterbarSelectRange: .activitylogFilterbarSelectRange,
            filterbarResetRange: .activitylogFilterbarResetRange,
            numberOfItemsPerPage: 20
        )

        super.init(site: site, store: store, configuration: activityListConfiguration, isFreeWPCom: isFreeWPCom)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        WPAnalytics.track(.activityLogViewed)
    }
}
