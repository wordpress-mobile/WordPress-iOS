import WordPressFlux

protocol ActivityPresenter: AnyObject {
    func presentDetailsFor(activity: FormattableActivity)
    func presentBackupOrRestoreFor(activity: Activity, from sender: UIButton)
    func presentRestoreFor(activity: Activity, from: String?)
    func presentBackupFor(activity: Activity, from: String?)
}

class ActivityListViewModel: Observable {

    let site: JetpackSiteRef
    let store: ActivityStore

    let changeDispatcher = Dispatcher<Void>()

    private let activitiesReceipt: Receipt
    private let rewindStatusReceipt: Receipt
    private let noResultsTexts: ActivityListConfiguration
    private var storeReceipt: Receipt?

    private var numberOfItemsPerPage = 20
    private var page = 0
    private(set) var after: Date?
    private(set) var before: Date?
    private(set) var selectedGroups: [ActivityGroup] = []

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

    var dateFilterIsActive: Bool {
        return after != nil || before != nil
    }

    var groupFilterIsActive: Bool {
        return !selectedGroups.isEmpty
    }

    var isAnyFilterActive: Bool {
        return dateFilterIsActive || groupFilterIsActive
    }

    var groups: [ActivityGroup] {
        return store.state.groups[site] ?? []
    }

    lazy var downloadPromptView: AppFeedbackPromptView = {
        AppFeedbackPromptView()
    }()

    init(site: JetpackSiteRef,
         store: ActivityStore = StoreContainer.shared.activity,
         configuration: ActivityListConfiguration) {
        self.site = site
        self.store = store
        self.noResultsTexts = configuration

        numberOfItemsPerPage = configuration.numberOfItemsPerPage
        store.numberOfItemsPerPage = numberOfItemsPerPage

        activitiesReceipt = store.query(.activities(site: site))
        rewindStatusReceipt = store.query(.restoreStatus(site: site))

        storeReceipt = store.onChange { [weak self] in
            self?.updateState()
        }
    }

    private func updateState() {
        changeDispatcher.dispatch()
        refreshing = store.isFetchingActivities(site: site)
    }

    public func refresh(after: Date? = nil, before: Date? = nil, group: [ActivityGroup] = []) {
        store.fetchRewindStatus(site: site)

        ActionDispatcher.dispatch(ActivityAction.refreshBackupStatus(site: site))

        // If a new filter is being applied, remove all activities
        if isApplyingNewFilter(after: after, before: before, group: group) {
            ActionDispatcher.dispatch(ActivityAction.resetActivities(site: site))
        }

        // If a new date range is being applied, remove the current activity types
        if isApplyingDateFilter(after: after, before: before) {
            ActionDispatcher.dispatch(ActivityAction.resetGroups(site: site))
        }

        self.page = 0
        self.after = after
        self.before = before
        self.selectedGroups = group

        ActionDispatcher.dispatch(ActivityAction.refreshActivities(site: site, quantity: numberOfItemsPerPage, afterDate: after, beforeDate: before, group: group.map { $0.key }))
    }

    public func loadMore() {
        if !store.isFetchingActivities(site: site) {
            page += 1
            let offset = page * numberOfItemsPerPage
            ActionDispatcher.dispatch(ActivityAction.loadMoreActivities(site: site, quantity: numberOfItemsPerPage, offset: offset, afterDate: after, beforeDate: before, group: selectedGroups.map { $0.key }))
        }
    }

    public func removeDateFilter() {
        refresh(after: nil, before: nil, group: selectedGroups)
    }

    public func removeGroupFilter() {
        refresh(after: after, before: before, group: [])
    }

    public func refreshGroups() {
        ActionDispatcher.dispatch(ActivityAction.refreshGroups(site: site, afterDate: after, beforeDate: before))
    }

    func noResultsViewModel() -> NoResultsViewController.Model? {
        guard store.getActivities(site: site) == nil ||
              store.getActivities(site: site)?.isEmpty == true else {
            return nil
        }

        if store.isFetchingActivities(site: site) {
            return NoResultsViewController.Model(title: noResultsTexts.loadingTitle, accessoryView: NoResultsViewController.loadingAccessoryView())
        }

        if let activites = store.getActivities(site: site), activites.isEmpty {
            if isAnyFilterActive {
                return NoResultsViewController.Model(title: noResultsTexts.noMatchingTitle, subtitle: noResultsTexts.noMatchingSubtitle)
            } else {
                return NoResultsViewController.Model(title: noResultsTexts.noActivitiesTitle, subtitle: NoResultsText.noActivitiesSubtitle)
            }
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

    func noResultsGroupsViewModel() -> NoResultsViewController.Model? {
        guard store.getGroups(site: site) == nil ||
              store.getGroups(site: site)?.isEmpty == true else {
            return nil
        }

        if store.isFetchingGroups(site: site) {
            return NoResultsViewController.Model(title: noResultsTexts.loadingTitle, accessoryView: NoResultsViewController.loadingAccessoryView())
        }

        if let groups = store.getGroups(site: site), groups.isEmpty {
            return NoResultsViewController.Model(title: NoResultsText.noGroupsTitle, subtitle: NoResultsText.noGroupsSubtitle)
        }

        let appDelegate = WordPressAppDelegate.shared
        if (appDelegate?.connectionAvailable)! {
            return NoResultsViewController.Model(title: NoResultsText.errorTitle,
                                                 subtitle: NoResultsText.errorSubtitle,
                                                 buttonText: NoResultsText.groupsErrorButtonText)
        } else {
            return NoResultsViewController.Model(title: NoResultsText.noConnectionTitle, subtitle: NoResultsText.noConnectionSubtitle)
        }
    }

    func tableViewModel(presenter: ActivityPresenter) -> ImmuTable {
        guard let activities = store.getActivities(site: site) else {
            return .Empty
        }
        let formattableActivities = activities.map(FormattableActivity.init)
        let activitiesRows = formattableActivities.map({ formattableActivity in
            return ActivityListRow(
                formattableActivity: formattableActivity,
                action: { [weak presenter] (row) in
                    presenter?.presentDetailsFor(activity: formattableActivity)
                },
                actionButtonHandler: { [weak presenter] (button) in
                    presenter?.presentBackupOrRestoreFor(activity: formattableActivity.activity, from: button)
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

        return ImmuTable(optionalSections: [backupStatusSection(), restoreStatusSection()] + activitiesSections)
        // So far the only "extra" section is the restore one. In the future, this will include
        // showing plugin updates/CTA's and other things like this.
    }

    func dateRangeDescription() -> String? {
        guard after != nil || before != nil else {
            return NSLocalizedString("Date Range", comment: "Label of a button that displays a calendar")
        }

        let format = shouldDisplayFullYear(with: after, and: before) ? "MMM d, yyyy" : "MMM d"
        dateFormatter.setLocalizedDateFormatFromTemplate(format)

        var formattedDateRanges: [String] = []

        if let after = after {
            formattedDateRanges.append(dateFormatter.string(from: after))
        }

        if let before = before {
            formattedDateRanges.append(dateFormatter.string(from: before))
        }

        return formattedDateRanges.joined(separator: " - ")
    }

    func backupDownloadHeader() -> UIView? {
        guard let validUntil = store.getBackupStatus(site: site)?.validUntil,
              Date() < validUntil,
              let backupPoint = store.getBackupStatus(site: site)?.backupPoint,
              let downloadURLString = store.getBackupStatus(site: site)?.url,
              let downloadURL = URL(string: downloadURLString),
              let downloadID = store.getBackupStatus(site: site)?.downloadID else {
            return nil
        }

        let headingMessage = NSLocalizedString("We successfully created a backup of your site as of %@", comment: "Message displayed when a backup has finished")
        downloadPromptView.setupHeading(String.init(format: headingMessage, arguments: [longDateFormatterWithTime.string(from: backupPoint)]))

        let downloadTitle = NSLocalizedString("Download", comment: "Download button title")
        downloadPromptView.setupYesButton(title: downloadTitle) { _ in
            UIApplication.shared.open(downloadURL)
        }

        let dismissTitle = NSLocalizedString("Dismiss", comment: "Dismiss button title")
        downloadPromptView.setupNoButton(title: dismissTitle) { [weak self] button in
            guard let self = self else {
                return
            }

            ActionDispatcher.dispatch(ActivityAction.dismissBackupNotice(site: self.site, downloadID: downloadID))
        }

        return downloadPromptView
    }

    func activityTypeDescription() -> String? {
        if selectedGroups.isEmpty {
            return NSLocalizedString("Activity Type", comment: "Label for the Activity Type filter button")
        } else if selectedGroups.count > 1 {
            return String.localizedStringWithFormat(NSLocalizedString("Activity Type (%1$d)", comment: "Label for the Activity Type filter button when there are more than 1 activity type selected"), selectedGroups.count)
        }

        return selectedGroups.first?.name
    }

    private func shouldDisplayFullYear(with firstDate: Date?, and secondDate: Date?) -> Bool {
        guard let firstDate = firstDate, let secondDate = secondDate else {
            return false
        }

        let currentYear = Calendar.current.dateComponents([.year], from: Date()).year
        let firstYear = Calendar.current.dateComponents([.year], from: firstDate).year
        let secondYear = Calendar.current.dateComponents([.year], from: secondDate).year

        return firstYear != currentYear || secondYear != currentYear
    }

    private func isApplyingNewFilter(after: Date? = nil, before: Date? = nil, group: [ActivityGroup]) -> Bool {
        let isSameGroup = group.count == self.selectedGroups.count && self.selectedGroups.elementsEqual(group, by: { $0.key == $1.key })

        return isApplyingDateFilter(after: after, before: before) || !isSameGroup
    }

    private func isApplyingDateFilter(after: Date? = nil, before: Date? = nil) -> Bool {
        after != self.after || before != self.before
    }

    private func backupStatusSection() -> ImmuTableSection? {
        guard let backup = store.getBackupStatus(site: site), let backupProgress = backup.progress else {
            return nil
        }

        let title = NSLocalizedString("Backing up site", comment: "Title of the cell displaying status of a backup in progress")
        let summary: String
        let progress = max(Float(backupProgress) / 100, 0.05)
        // We don't want to show a completely empty progress bar — it'd seem something is broken. 5% looks acceptable
        // for the starting state.

        summary = NSLocalizedString("Creating downloadable backup", comment: "Description of the cell displaying status of a backup in progress")

        let rewindRow = RewindStatusRow(
            title: title,
            summary: summary,
            progress: progress
        )

        return ImmuTableSection(headerText: NSLocalizedString("Backup", comment: "Title of section showing backup status"),
                                rows: [rewindRow],
                                footerText: nil)
    }

    private func restoreStatusSection() -> ImmuTableSection? {
        guard let restore = store.getCurrentRewindStatus(site: site)?.restore, restore.status == .running || restore.status == .queued else {
            return nil
        }

        let title = NSLocalizedString("Currently restoring your site", comment: "Title of the cell displaying status of a rewind in progress")
        let summary: String
        let progress = max(Float(restore.progress) / 100, 0.05)
        // We don't want to show a completely empty progress bar — it'd seem something is broken. 5% looks acceptable
        // for the starting state.

        if let rewindPoint = store.getActivity(site: site, rewindID: restore.id) {
            let dateString = mediumDateFormatterWithTime.string(from: rewindPoint.published)

            let messageFormat = NSLocalizedString("Restoring to %@",
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

        let headerText = NSLocalizedString("Restore", comment: "Title of section showing restore status")

        return ImmuTableSection(headerText: headerText,
                                rows: [rewindRow],
                                footerText: nil)
    }

    private struct NoResultsText {
        static let noActivitiesSubtitle = NSLocalizedString("When you make changes to your site you'll be able to see your activity history here.", comment: "Text display when the view when there aren't any Activities to display in the Activity Log")
        static let errorTitle = NSLocalizedString("Oops", comment: "Title for the view when there's an error loading Activity Log")
        static let errorSubtitle = NSLocalizedString("There was an error loading activities", comment: "Text displayed when there is a failure loading the activity feed")
        static let errorButtonText = NSLocalizedString("Contact support", comment: "Button label for contacting support")
        static let noConnectionTitle = NSLocalizedString("No connection", comment: "Title for the error view when there's no connection")
        static let noConnectionSubtitle = NSLocalizedString("An active internet connection is required to view activities", comment: "Error message shown when trying to view the Activity Log feature and there is no internet connection.")
        static let noGroupsTitle = NSLocalizedString("No activities available", comment: "Title for the view when there aren't any Activities Types to display in the Activity Log Types picker")
        static let noGroupsSubtitle = NSLocalizedString("No activities recorded in the selected date range.", comment: "Text display in the view when there aren't any Activities Types to display in the Activity Log Types picker")
        static let groupsErrorButtonText = NSLocalizedString("Try again", comment: "Button label for trying to retrieve the activities type again")
    }

    // MARK: - Date/Time handling

    lazy var longDateFormatterWithoutTime: DateFormatter = {
        return ActivityDateFormatting.longDateFormatter(for: site, withTime: false)
    }()

    lazy var longDateFormatterWithTime: DateFormatter = {
        return ActivityDateFormatting.longDateFormatter(for: site, withTime: true)
    }()

    lazy var mediumDateFormatterWithTime: DateFormatter = {
        return ActivityDateFormatting.mediumDateFormatterWithTime(for: site)
    }()

    lazy var dateFormatter: DateFormatter = {
        DateFormatter()
    }()
}

extension ActivityGroup: Equatable {
    public static func == (lhs: ActivityGroup, rhs: ActivityGroup) -> Bool {
        lhs.key == rhs.key
    }
}
