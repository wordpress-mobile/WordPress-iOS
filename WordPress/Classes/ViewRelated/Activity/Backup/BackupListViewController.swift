import Foundation
import Combine

class BackupListViewController: BaseActivityListViewController {

    override init(site: JetpackSiteRef, store: ActivityStore, isFreeWPCom: Bool = false) {
        store.onlyRestorableItems = true

        let activityListConfiguration = ActivityListConfiguration(
            identifier: "backup",
            title: NSLocalizedString("Backup", comment: "Title for the Jetpack's backup list"),
            loadingTitle: NSLocalizedString("Loading Backups...", comment: "Text displayed while loading the activity feed for a site"),
            noActivitiesTitle: NSLocalizedString("Your first backup will be ready soon", comment: "Title for the view when there aren't any Backups to display"),
            noActivitiesSubtitle: NSLocalizedString("Your first backup will appear here within 24 hours and you will receive a notification once the backup has been completed", comment: "Text displayed in the view when there aren't any Backups to display"),
            noMatchingTitle: NSLocalizedString("No matching backups found", comment: "Title for the view when there aren't any backups to display for a given filter."),
            noMatchingSubtitle: NSLocalizedString("Try adjusting your date range filter", comment: "Text displayed in the view when there aren't any backups to display for a given filter."),
            filterbarRangeButtonTapped: .backupFilterbarRangeButtonTapped,
            filterbarSelectRange: .backupFilterbarSelectRange,
            filterbarResetRange: .backupFilterbarResetRange,
            numberOfItemsPerPage: 100
        )

        super.init(site: site, store: store, configuration: activityListConfiguration, isFreeWPCom: isFreeWPCom)

        activityTypeFilterChip.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let siteRef = JetpackSiteRef(blog: blog) else {
            return nil
        }

        let isFreeWPCom = blog.isHostedAtWPcom && !blog.hasPaidPlan
        self.init(site: siteRef, store: StoreContainer.shared.activity, isFreeWPCom: isFreeWPCom)
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        extendedLayoutIncludesOpaqueBars = true

        tableView.accessibilityIdentifier = "jetpack-backup-table"

        WPAnalytics.track(.backupListOpened)
    }
}
