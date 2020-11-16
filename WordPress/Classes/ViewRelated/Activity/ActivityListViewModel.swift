import WordPressFlux

protocol ActivityRewindPresenter: class {
    func presentRewindFor(activity: Activity)
}

protocol ActivityDetailPresenter: class {
    func presentDetailsFor(activity: FormattableActivity)
}

class ActivityListViewModel: Observable {

    let site: JetpackSiteRef
    let store: ActivityStore

    let changeDispatcher = Dispatcher<Void>()

    private let activitiesReceipt: Receipt
    private let rewindStatusReceipt: Receipt
    private var storeReceipt: Receipt?

    private let count = 20
    private var offset = 0

    var errorViewModel: NoResultsViewController.Model?
    private(set) var refreshing = false {
        didSet {
            if refreshing != oldValue {
                emitChange()
            }
        }
    }

    var hasMore: Bool {
        store.state.hasMore
    }

    init(site: JetpackSiteRef, store: ActivityStore = StoreContainer.shared.activity) {
        self.site = site
        self.store = store

        activitiesReceipt = store.query(.activities(site: site))
        rewindStatusReceipt = store.query(.restoreStatus(site: site))

        storeReceipt = store.onChange { [weak self] in
            self?.updateState()
        }
    }

    private func updateState() {
        changeDispatcher.dispatch()
        refreshing = store.isFetching(site: site)
    }

    public func refresh() {
        ActionDispatcher.dispatch(ActivityAction.refreshActivities(site: site, quantity: count))
    }

    public func loadMore() {
        if !store.isFetching(site: site) {
            offset = store.state.activities[site]?.count ?? 0
            ActionDispatcher.dispatch(ActivityAction.loadMoreActivities(site: site, quantity: count, offset: offset))
        }
    }

    func noResultsViewModel() -> NoResultsViewController.Model? {
        guard store.getActivities(site: site) == nil ||
              store.getActivities(site: site)?.isEmpty == true else {
            return nil
        }

        if store.isFetching(site: site) {
            return NoResultsViewController.Model(title: NoResultsText.loadingTitle, accessoryView: NoResultsViewController.loadingAccessoryView())
        }

        if let activites = store.getActivities(site: site), activites.isEmpty {
            return NoResultsViewController.Model(title: NoResultsText.noActivitiesTitle, subtitle: NoResultsText.noActivitiesSubtitle)
        }

        let appDelegate = WordPressAppDelegate.shared
        if (appDelegate?.connectionAvailable)! {
            return NoResultsViewController.Model(title: NoResultsText.errorTitle,
                                                 subtitle: NoResultsText.errorSubtitle,
                                                 buttonText: NoResultsText.errorButtonText)
        } else {
            return NoResultsViewController.Model(title: NoResultsText.noConnectionTitle, subtitle: NoResultsText.noConnectionSubtitle)
        }
    }

    func tableViewModel(presenter: ActivityDetailPresenter) -> ImmuTable {
        guard let activities = store.getActivities(site: site) else {
            return .Empty
        }
        let formattableActivities = activities.map(FormattableActivity.init)
        let activitiesRows = formattableActivities.map({ formattableActivity in
            return ActivityListRow(
                formattableActivity: formattableActivity,
                action: { [weak presenter] (row) in
                    presenter?.presentDetailsFor(activity: formattableActivity)
                }
            )
        })

        let groupedRows = activitiesRows.sortedGroup {
            return longDateFormatterWithoutTime.string(from: $0.activity.published)
        }

        let activitiesSections = groupedRows
            .map { (date, rows) in
                return ImmuTableSection(headerText: date,
                                        optionalRows: rows,
                                        footerText: nil)
            }

        return ImmuTable(optionalSections: [restoreStatusSection()] + activitiesSections)
        // So far the only "extra" section is the restore one. In the future, this will include
        // showing plugin updates/CTA's and other things like this.
    }

    private func restoreStatusSection() -> ImmuTableSection? {
        guard let restore = store.getRewindStatus(site: site)?.restore, restore.status == .running || restore.status == .queued else {
            return nil
        }

        let title = NSLocalizedString("Currently restoring your site", comment: "Title of the cell displaying status of a rewind in progress")
        let summary: String
        let progress = max(Float(restore.progress) / 100, 0.05)
        // We don't want to show a completely empty progress bar — it'd seem something is broken. 5% looks acceptable
        // for the starting state.

        if let rewindPoint = store.getActivity(site: site, rewindID: restore.id) {
            let dateString = mediumDateFormatterWithTime.string(from: rewindPoint.published)
            let messageFormat = NSLocalizedString("Rewinding to %@",
                comment: "Text showing the point in time the site is being currently restored to. %@' is a placeholder that will expand to a date.")

            summary = String(format: messageFormat, dateString)
        } else {
            summary = ""
        }

        let rewindRow = RewindStatusRow(
            title: title,
            summary: summary,
            progress: progress
        )

        return ImmuTableSection(headerText: NSLocalizedString("Rewind", comment: "Title of section showing rewind status"),
                                rows: [rewindRow],
                                footerText: nil)
    }

    private struct NoResultsText {
        static let loadingTitle = NSLocalizedString("Loading Activities...", comment: "Text displayed while loading the activity feed for a site")
        static let noActivitiesTitle = NSLocalizedString("No activity yet", comment: "Title for the view when there aren't any Activities to display in the Activity Log")
        static let noActivitiesSubtitle = NSLocalizedString("When you make changes to your site you'll be able to see your activity history here.", comment: "Text display when the view when there aren't any Activities to display in the Activity Log")
        static let errorTitle = NSLocalizedString("Oops", comment: "Title for the view when there's an error loading Activity Log")
        static let errorSubtitle = NSLocalizedString("There was an error loading activities", comment: "Text displayed when there is a failure loading the activity feed")
        static let errorButtonText = NSLocalizedString("Contact support", comment: "Button label for contacting support")
        static let noConnectionTitle = NSLocalizedString("No connection", comment: "Title for the error view when there's no connection")
        static let noConnectionSubtitle = NSLocalizedString("An active internet connection is required to view activities", comment: "Error message shown when trying to view the Activity Log feature and there is no internet connection.")
    }

    // MARK: - Date/Time handling

    lazy var longDateFormatterWithoutTime: DateFormatter = {
        return ActivityDateFormatting.longDateFormatterWithoutTime(for: site)
    }()

    lazy var mediumDateFormatterWithTime: DateFormatter = {
        return ActivityDateFormatting.mediumDateFormatterWithTime(for: site)
    }()
}
