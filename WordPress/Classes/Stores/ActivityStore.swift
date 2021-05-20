import Foundation
import WordPressKit
import WordPressFlux

// MARK: - Store helper types

enum ActivityAction: Action {
    case refreshActivities(site: JetpackSiteRef, quantity: Int, afterDate: Date?, beforeDate: Date?, group: [String])
    case loadMoreActivities(site: JetpackSiteRef, quantity: Int, offset: Int, afterDate: Date?, beforeDate: Date?, group: [String])
    case receiveActivities(site: JetpackSiteRef, activities: [Activity], hasMore: Bool, loadingMore: Bool)
    case receiveActivitiesFailed(site: JetpackSiteRef, error: Error)
    case resetActivities(site: JetpackSiteRef)

    case rewind(site: JetpackSiteRef, rewindID: String)
    case rewindStarted(site: JetpackSiteRef, rewindID: String, restoreID: String)
    case rewindRequestFailed(site: JetpackSiteRef, error: Error)
    case rewindFinished(site: JetpackSiteRef, restoreID: String)
    case rewindFailed(site: JetpackSiteRef, restoreID: String)

    case rewindStatusUpdated(site: JetpackSiteRef, status: RewindStatus)
    case rewindStatusUpdateFailed(site: JetpackSiteRef, error: Error)
    case rewindStatusUpdateTimedOut(site: JetpackSiteRef)

    case refreshBackupStatus(site: JetpackSiteRef)
    case backupStatusUpdated(site: JetpackSiteRef, status: JetpackBackup)
    case backupStatusUpdateFailed(site: JetpackSiteRef, error: Error)
    case backupStatusUpdateTimedOut(site: JetpackSiteRef)
    case dismissBackupNotice(site: JetpackSiteRef, downloadID: Int)

    case refreshGroups(site: JetpackSiteRef, afterDate: Date?, beforeDate: Date?)
    case resetGroups(site: JetpackSiteRef)
}

enum ActivityQuery {
    case activities(site: JetpackSiteRef)
    case restoreStatus(site: JetpackSiteRef)
    case backupStatus(site: JetpackSiteRef)

    var site: JetpackSiteRef {
        switch self {
        case .activities(let site):
            return site
        case .restoreStatus(let site):
            return site
        case .backupStatus(let site):
            return site
        }
    }
}

struct ActivityStoreState {
    var activities = [JetpackSiteRef: [Activity]]()
    var lastFetch = [JetpackSiteRef: Date]()
    var fetchingActivities = [JetpackSiteRef: Bool]()
    var hasMore = false

    var groups = [JetpackSiteRef: [ActivityGroup]]()
    var fetchingGroups = [JetpackSiteRef: Bool]()

    var rewindStatus = [JetpackSiteRef: RewindStatus]()
    var fetchingRewindStatus = [JetpackSiteRef: Bool]()

    var backupStatus = [JetpackSiteRef: JetpackBackup]()
    var fetchingBackupStatus = [JetpackSiteRef: Bool]()

    // This needs to be `fileprivate` because `DelayStateWrapper` is private.
    fileprivate var rewindStatusRetries = [JetpackSiteRef: DelayStateWrapper]()
    fileprivate var backupStatusRetries = [JetpackSiteRef: DelayStateWrapper]()
}


private enum Constants {
    /// Sequence of increasing delays to apply to the fetch restore status mechanism (in seconds)
    static let delaySequence = [1, 5]
    static let maxRetries = 12
}

enum ActivityStoreError: Error {
    case rewindAlreadyRunning
}

class ActivityStore: QueryStore<ActivityStoreState, ActivityQuery> {

    private let refreshInterval: TimeInterval = 60

    private let activityServiceRemote: ActivityServiceRemote?

    private let backupService: JetpackBackupService

    /// When set to true, this store will only return items that are restorable
    var onlyRestorableItems = false

    var numberOfItemsPerPage = 20

    override func queriesChanged() {
        super.queriesChanged()
        processQueries()
    }

    init(dispatcher: ActionDispatcher = .global,
         activityServiceRemote: ActivityServiceRemote? = nil,
         backupService: JetpackBackupService? = nil) {
        self.activityServiceRemote = activityServiceRemote
        self.backupService = backupService ?? JetpackBackupService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        super.init(initialState: ActivityStoreState(), dispatcher: dispatcher)
    }

    override func logError(_ error: String) {
        DDLogError(error)
    }

    func processQueries() {
        guard !activeQueries.isEmpty else {
            transaction { state in
                state.activities = [:]
                state.rewindStatus = [:]
                state.backupStatus = [:]
                state.rewindStatusRetries = [:]
                state.lastFetch = [:]
                state.fetchingActivities = [:]
                state.fetchingRewindStatus = [:]
                state.fetchingBackupStatus = [:]
            }
            return
        }

        // Fetching Activities.
        sitesToFetch
            .forEach { fetchActivities(site: $0, count: numberOfItemsPerPage) }


        // Fetching Status
        sitesStatusesToFetch
            .filter { state.fetchingRewindStatus[$0] != true }
            .forEach {
                fetchRewindStatus(site: $0)
        }

        // Fetching Backup Status
        sitesStatusesToFetch
            .filter { state.fetchingBackupStatus[$0] != true }
            .forEach {
                fetchBackupStatus(site: $0)
        }
    }
    private var sitesToFetch: [JetpackSiteRef] {
        return activeQueries
            .filter {
                if case .activities = $0 {
                    return true
                } else {
                    return false
                }
            }
            .compactMap { $0.site }
            .unique
            .filter { shouldFetch(site: $0) }
    }

    private var sitesStatusesToFetch: [JetpackSiteRef] {
        return activeQueries
            .filter {
                if case .restoreStatus = $0 {
                    return true
                } else if case .backupStatus = $0 {
                    return true
                } else {
                    return false
                }
            }
            .compactMap { $0.site }
            .unique
    }

    func shouldFetch(site: JetpackSiteRef) -> Bool {
        let lastFetch = state.lastFetch[site, default: .distantPast]
        let needsRefresh = lastFetch + refreshInterval < Date()
        let currentlyFetching = isFetchingActivities(site: site)
        return needsRefresh && !currentlyFetching
    }

    func isFetchingActivities(site: JetpackSiteRef) -> Bool {
        return state.fetchingActivities[site, default: false]
    }

    func isFetchingGroups(site: JetpackSiteRef) -> Bool {
        return state.fetchingGroups[site, default: false]
    }

    override func onDispatch(_ action: Action) {
        guard let activityAction = action as? ActivityAction else {
            return
        }

        switch activityAction {
        case .receiveActivities(let site, let activities, let hasMore, let loadingMore):
            receiveActivities(site: site, activities: activities, hasMore: hasMore, loadingMore: loadingMore)
        case .loadMoreActivities(let site, let quantity, let offset, let afterDate, let beforeDate, let group):
            loadMoreActivities(site: site, quantity: quantity, offset: offset, afterDate: afterDate, beforeDate: beforeDate, group: group)
        case .receiveActivitiesFailed(let site, let error):
            receiveActivitiesFailed(site: site, error: error)
        case .refreshActivities(let site, let quantity, let afterDate, let beforeDate, let group):
            refreshActivities(site: site, quantity: quantity, afterDate: afterDate, beforeDate: beforeDate, group: group)
        case .resetActivities(let site):
            resetActivities(site: site)
        case .rewind(let site, let rewindID):
            rewind(site: site, rewindID: rewindID)
        case .rewindStarted(let site, let rewindID, let restoreID):
            rewindStarted(site: site, rewindID: rewindID, restoreID: restoreID)
        case .rewindRequestFailed(let site, let error):
            rewindFailed(site: site, error: error)
        case .rewindStatusUpdated(let site, let status):
            rewindStatusUpdated(site: site, status: status)
        case .rewindStatusUpdateFailed(let site, _):
            delayedRetryFetchRewindStatus(site: site)
        case .rewindFinished(let site, let restoreID):
            rewindFinished(site: site, restoreID: restoreID)
        case .rewindFailed(let site, _),
             .rewindStatusUpdateTimedOut(let site):
            transaction { state in
                state.fetchingRewindStatus[site] = false
                state.rewindStatusRetries[site] = nil
            }

            if shouldPostStateUpdates(for: site) {
                let notice = Notice(title: NSLocalizedString("Your restore is taking longer than usual, please check again in a few minutes.",
                                                             comment: "Text displayed when a site restore takes too long."))
                actionDispatcher.dispatch(NoticeAction.post(notice))
            }
        case .refreshGroups(let site, let afterDate, let beforeDate):
            refreshGroups(site: site, afterDate: afterDate, beforeDate: beforeDate)
        case .resetGroups(let site):
            resetGroups(site: site)
        case .refreshBackupStatus(let site):
            fetchBackupStatus(site: site)
        case .backupStatusUpdated(let site, let status):
            backupStatusUpdated(site: site, status: status)
        case .backupStatusUpdateFailed(let site, _):
            delayedRetryFetchBackupStatus(site: site)
        case .backupStatusUpdateTimedOut(let site):
            transaction { state in
                state.fetchingBackupStatus[site] = false
                state.backupStatusRetries[site] = nil
            }

            if shouldPostStateUpdates(for: site) {
                let notice = Notice(title: NSLocalizedString("Your backup is taking longer than usual, please check again in a few minutes.",
                                                             comment: "Text displayed when a site backup takes too long."))
                actionDispatcher.dispatch(NoticeAction.post(notice))
            }
        case .dismissBackupNotice(let site, let downloadID):
            dismissBackupNotice(site: site, downloadID: downloadID)
        }
    }
}
// MARK: - Selectors
extension ActivityStore {
    func getActivities(site: JetpackSiteRef) -> [Activity]? {
        return state.activities[site] ?? nil
    }

    func getGroups(site: JetpackSiteRef) -> [ActivityGroup]? {
        return state.groups[site] ?? nil
    }

    func getActivity(site: JetpackSiteRef, rewindID: String) -> Activity? {
        return getActivities(site: site)?.filter { $0.rewindID == rewindID }.first
    }

    func getCurrentRewindStatus(site: JetpackSiteRef) -> RewindStatus? {
        return state.rewindStatus[site] ?? nil
    }

    func getBackupStatus(site: JetpackSiteRef) -> JetpackBackup? {
        return state.backupStatus[site] ?? nil
    }

    func isRestoreAlreadyRunning(site: JetpackSiteRef) -> Bool {
        let currentStatus = getCurrentRewindStatus(site: site)
        let restoreStatus = currentStatus?.restore?.status
        return currentStatus != nil && (restoreStatus == .running || restoreStatus == .queued)
    }

    func isAwaitingCredentials(site: JetpackSiteRef) -> Bool {
        let currentStatus = getCurrentRewindStatus(site: site)
        return currentStatus?.state == .awaitingCredentials
    }

    func fetchRewindStatus(site: JetpackSiteRef) {
        state.fetchingRewindStatus[site] = true

        remote(site: site)?.getRewindStatus(
            site.siteID,
            success: { [actionDispatcher] rewindStatus in
                actionDispatcher.dispatch(ActivityAction.rewindStatusUpdated(site: site, status: rewindStatus))
            },
            failure: { [actionDispatcher] error in
                actionDispatcher.dispatch(ActivityAction.rewindStatusUpdateFailed(site: site, error: error))
        })
    }

    func fetchBackupStatus(site: JetpackSiteRef) {
        state.fetchingBackupStatus[site] = true

        backupService.getAllBackupStatus(for: site, success: { [actionDispatcher] backupsStatus in
            guard let status = backupsStatus.first else {
                return
            }

            actionDispatcher.dispatch(ActivityAction.backupStatusUpdated(site: site, status: status))
        }, failure: { [actionDispatcher] error in
            actionDispatcher.dispatch(ActivityAction.backupStatusUpdateFailed(site: site, error: error))
        })
    }

}

private extension ActivityStore {
    func fetchActivities(site: JetpackSiteRef,
                         count: Int,
                         offset: Int = 0,
                         afterDate: Date? = nil,
                         beforeDate: Date? = nil,
                         group: [String] = []) {
        state.fetchingActivities[site] = true

        remote(site: site)?.getActivityForSite(
            site.siteID,
            offset: offset,
            count: count,
            after: afterDate,
            before: beforeDate,
            group: group,
            success: { [weak self, actionDispatcher] (activities, hasMore) in
                guard let self = self else {
                    return
                }

                let loadingMore = offset > 0
                actionDispatcher.dispatch(
                    ActivityAction.receiveActivities(
                        site: site,
                        activities: self.onlyRestorableItems ? activities.filter { $0.isRewindable } : activities,
                        hasMore: hasMore,
                        loadingMore: loadingMore)
                )
        },
            failure: { [actionDispatcher] error in
                actionDispatcher.dispatch(ActivityAction.receiveActivitiesFailed(site: site, error: error))
        })
    }

    func receiveActivities(site: JetpackSiteRef, activities: [Activity], hasMore: Bool = false, loadingMore: Bool = false) {
        transaction { state in
            let allActivities = loadingMore ? (state.activities[site] ?? []) + activities : activities
            state.activities[site] = allActivities
            state.fetchingActivities[site] = false
            state.lastFetch[site] = Date()
            state.hasMore = hasMore
        }
    }

    func receiveActivitiesFailed(site: JetpackSiteRef, error: Error) {
        transaction { state in
            state.fetchingActivities[site] = false
            state.lastFetch[site] = Date()
        }
    }

    func refreshActivities(site: JetpackSiteRef, quantity: Int, afterDate: Date?, beforeDate: Date?, group: [String]) {
        guard !isFetchingActivities(site: site) else {
            DDLogInfo("Activity Log refresh triggered while one was in progress")
            return
        }
        fetchActivities(site: site, count: quantity, afterDate: afterDate, beforeDate: beforeDate, group: group)
    }

    func loadMoreActivities(site: JetpackSiteRef, quantity: Int, offset: Int, afterDate: Date?, beforeDate: Date?, group: [String]) {
        guard !isFetchingActivities(site: site) else {
            DDLogInfo("Activity Log refresh triggered while one was in progress")
            return
        }
        fetchActivities(site: site, count: quantity, offset: offset, afterDate: afterDate, beforeDate: beforeDate, group: group)
    }

    func resetActivities(site: JetpackSiteRef) {
        transaction { state in
            state.activities[site] = []
            state.fetchingActivities[site] = false
            state.lastFetch[site] = Date()
            state.hasMore = false
        }
    }

    func rewind(site: JetpackSiteRef, rewindID: String) {
        if isRestoreAlreadyRunning(site: site) {
            actionDispatcher.dispatch(ActivityAction.rewindRequestFailed(site: site, error: ActivityStoreError.rewindAlreadyRunning))
            return
        }

        remoteV1(site: site)?.restoreSite(
            site.siteID,
            rewindID: rewindID,
            success: { [actionDispatcher] restoreID, _ in
                actionDispatcher.dispatch(ActivityAction.rewindStarted(site: site, rewindID: rewindID, restoreID: restoreID))
            },
            failure: {  [actionDispatcher] error in
                actionDispatcher.dispatch(ActivityAction.rewindRequestFailed(site: site, error: error))
        })
    }

    func rewindStarted(site: JetpackSiteRef, rewindID: String, restoreID: String) {
        fetchRewindStatus(site: site)

        let notice: Notice
        let title = NSLocalizedString("Your site is being restored",
                                      comment: "Title of a message displayed when user starts a restore operation")

        if let activity = getActivity(site: site, rewindID: rewindID) {
            let formattedString = mediumString(from: activity.published, adjustingTimezoneTo: site)

            let message = String(format: NSLocalizedString("Restoring to %@", comment: "Notice showing the date the site is being restored to. '%@' is a placeholder that will expand to a date."), formattedString)
            notice = Notice(title: title, message: message)
        } else {
            notice = Notice(title: title)
        }
        WPAnalytics.track(.activityLogRewindStarted)
        actionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func rewindFinished(site: JetpackSiteRef, restoreID: String) {
        transaction { state in
            state.fetchingRewindStatus[site] = false
            state.rewindStatusRetries[site] = nil
        }

        let notice: Notice
        let title = NSLocalizedString("Your site has been succesfully restored",
                                      comment: "Title of a message displayed when a site has finished rewinding")

        if let activity = getActivity(site: site, rewindID: restoreID) {
            let formattedString = mediumString(from: activity.published, adjustingTimezoneTo: site)

            let message = String(format: NSLocalizedString("Restored to %@", comment: "Notice showing the date the site is being rewinded to. '%@' is a placeholder that will expand to a date."), formattedString)
            notice = Notice(title: title, message: message)
        } else {
            notice = Notice(title: title)
        }

        actionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func rewindFailed(site: JetpackSiteRef, error: Error) {
        let message: String
        switch error {
        case ActivityStoreError.rewindAlreadyRunning:
            message = NSLocalizedString("There's a restore currently in progress, please wait before starting next one",
                                        comment: "Text displayed when user tries to start a restore when there is already one running")
        default:
            message = NSLocalizedString("Unable to restore your site, please try again later or contact support.",
                                        comment: "Text displayed when a site restore fails.")
        }

        let noticeAction = NoticeAction.post(Notice(title: message))

        actionDispatcher.dispatch(noticeAction)
    }

    func delayedRetryFetchRewindStatus(site: JetpackSiteRef) {
        guard sitesStatusesToFetch.contains(site) == false else {
            // if we still have an active query asking about status of this site (e.g. it's still visible on screen)
            // let's keep retrying as long as it's registered — we want users to see the updates.
            // The retry logic should only kick-in when the site is off-screen, so we can pop-up a Notice
            // letting users know what's happening with their site.
            _ = DispatchDelayedAction(delay: .seconds(Constants.delaySequence.last!)) { [weak self] in
                self?.fetchRewindStatus(site: site)
            }
            return
        }

        // Note: this might look sorta weird, because it appears we're not at any point actually
        // scheduling the rewind, *but*: initiating/`increment`ing the `DelayStateWrapper` has a side-effect
        // of automagically calling the closure after an appropriate amount of time elapses.
        guard var existingWrapper = state.rewindStatusRetries[site] else {
            let newDelayWrapper = DelayStateWrapper(delaySequence: Constants.delaySequence) { [weak self] in
                self?.fetchRewindStatus(site: site)
            }

            state.rewindStatusRetries[site] = newDelayWrapper
            return
        }

        guard existingWrapper.retryAttempt < Constants.maxRetries else {
            existingWrapper.delayedRetryAction.cancel()
            actionDispatcher.dispatch(ActivityAction.rewindStatusUpdateTimedOut(site: site))
            return
        }

        existingWrapper.increment()
        state.rewindStatusRetries[site] = existingWrapper
    }

    func delayedRetryFetchBackupStatus(site: JetpackSiteRef) {
        guard sitesStatusesToFetch.contains(site) == false else {
            _ = DispatchDelayedAction(delay: .seconds(Constants.delaySequence.last!)) { [weak self] in
                self?.fetchBackupStatus(site: site)
            }
            return
        }

        guard var existingWrapper = state.backupStatusRetries[site] else {
            let newDelayWrapper = DelayStateWrapper(delaySequence: Constants.delaySequence) { [weak self] in
                self?.fetchBackupStatus(site: site)
            }

            state.backupStatusRetries[site] = newDelayWrapper
            return
        }

        guard existingWrapper.retryAttempt < Constants.maxRetries else {
            existingWrapper.delayedRetryAction.cancel()
            actionDispatcher.dispatch(ActivityAction.backupStatusUpdateTimedOut(site: site))
            return
        }

        existingWrapper.increment()
        state.backupStatusRetries[site] = existingWrapper
    }

    func dismissBackupNotice(site: JetpackSiteRef, downloadID: Int) {
        backupService.dismissBackupNotice(site: site, downloadID: downloadID)
        state.backupStatus[site] = nil
    }

    func rewindStatusUpdated(site: JetpackSiteRef, status: RewindStatus) {
        state.rewindStatus[site] = status

        guard let restoreStatus = status.restore else {
            return
        }

        switch restoreStatus.status {
        case .running, .queued:
            delayedRetryFetchRewindStatus(site: site)
        case .finished:
            if shouldPostStateUpdates(for: site) {
                actionDispatcher.dispatch(ActivityAction.rewindFinished(site: site, restoreID: restoreStatus.id))
            }
        case .fail:
            if shouldPostStateUpdates(for: site) {
                actionDispatcher.dispatch(ActivityAction.rewindFailed(site: site, restoreID: restoreStatus.id))
            }
        }
    }

    func backupStatusUpdated(site: JetpackSiteRef, status: JetpackBackup) {
        state.backupStatus[site] = status

        if let progress = status.progress, progress > 0 {
            delayedRetryFetchBackupStatus(site: site)
        }
    }

    func refreshGroups(site: JetpackSiteRef, afterDate: Date?, beforeDate: Date?) {
        guard !isFetchingGroups(site: site) else {
            DDLogInfo("Activity Log fetch groups triggered while one was in progress")
            return
        }

        state.fetchingGroups[site] = true

        if state.groups[site]?.isEmpty ?? true {
            remote(site: site)?.getActivityGroupsForSite(
                site.siteID,
                after: afterDate,
                before: beforeDate,
                success: { [weak self] groups in
                    self?.receiveGroups(site: site, groups: groups)
                }, failure: { [weak self] error in
                    self?.failedGroups(site: site)
                })
        } else {
            receiveGroups(site: site, groups: state.groups[site] ?? [])
        }
    }

    func receiveGroups(site: JetpackSiteRef, groups: [ActivityGroup]) {
        transaction { state in
            state.fetchingGroups[site] = false
            state.groups[site] = groups.sorted { $0.count > $1.count }
        }
    }

    func failedGroups(site: JetpackSiteRef) {
        transaction { state in
            state.fetchingGroups[site] = false
            state.groups[site] = nil
        }
    }

    func resetGroups(site: JetpackSiteRef) {
        transaction { state in
            state.groups[site] = []
            state.fetchingGroups[site] = false
        }
    }

    // MARK: - Helpers

    func remote(site: JetpackSiteRef) -> ActivityServiceRemote? {
        guard activityServiceRemote == nil else {
            return activityServiceRemote
        }

        guard let token = CredentialsService().getOAuthToken(site: site) else {
            return nil
        }

        let api = WordPressComRestApi.defaultApi(oAuthToken: token, userAgent: WPUserAgent.wordPress(), localeKey: WordPressComRestApi.LocaleKeyV2)

        return ActivityServiceRemote(wordPressComRestApi: api)
    }

    func remoteV1(site: JetpackSiteRef) -> ActivityServiceRemote_ApiVersion1_0? {
        guard let token = CredentialsService().getOAuthToken(site: site) else {
            return nil
        }
        let api = WordPressComRestApi.defaultApi(oAuthToken: token, userAgent: WPUserAgent.wordPress())

        return ActivityServiceRemote_ApiVersion1_0(wordPressComRestApi: api)
    }

    private func mediumString(from date: Date, adjustingTimezoneTo site: JetpackSiteRef) -> String {
        let formatter = ActivityDateFormatting.mediumDateFormatterWithTime(for: site)
        return formatter.string(from: date)
    }

    private func shouldPostStateUpdates(for site: JetpackSiteRef) -> Bool {
        // The way our API works, if there was a restore event "recently" (for some undefined value of "recently",
        // on the order of magnitude of ~30 minutes or so), it'll be reported back by the API.
        // But if the restore has finished a good while back (e.g. there's also an event in the AL telling us
        // about the restore happening) we don't neccesarily want to display that redundant info to the users.
        // Hence this somewhat dumb hack — if we've gotten updates about a RewindStatus before (which means we have displayed the UI)
        // we're gonna show users "hey, your rewind finished!". But if the only thing we know the restore is
        // that it has finished in a recent past, we don't do anything special.

        return getCurrentRewindStatus(site: site)?.restore?.status == .running ||
               getCurrentRewindStatus(site: site)?.restore?.status == .queued
    }
}
