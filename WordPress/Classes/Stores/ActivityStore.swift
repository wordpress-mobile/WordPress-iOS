import Foundation
import WordPressKit
import WordPressFlux

// MARK: - Store helper types

enum ActivityAction: Action {
    case receiveActivities(site: JetpackSiteRef, activities: [Activity])
    case receiveActivitiesFailed(site: JetpackSiteRef, error: Error)

    case rewind(site: JetpackSiteRef, rewindID: String)
    case rewindStarted(site: JetpackSiteRef, rewindID: String, restoreID: String)
    case rewindRequestFailed(site: JetpackSiteRef, error: Error)
    case rewindFinished(site: JetpackSiteRef, restoreID: String)
    case rewindFailed(site: JetpackSiteRef, restoreID: String)

    case rewindStatusUpdated(site: JetpackSiteRef, status: RewindStatus)
    case rewindStatusUpdateFailed(site: JetpackSiteRef, error: Error)
    case rewindStatusUpdateTimedOut(site: JetpackSiteRef)
}

enum ActivityQuery {
    case activities(site: JetpackSiteRef)
    case restoreStatus(site: JetpackSiteRef)

    var site: JetpackSiteRef {
        switch self {
        case .activities(let site):
            return site
        case .restoreStatus(let site):
            return site
        }
    }
}

struct ActivityStoreState {
    var activities = [JetpackSiteRef: [Activity]]()
    var lastFetch = [JetpackSiteRef: Date]()
    var fetchingActivities = [JetpackSiteRef: Bool]()

    var rewindStatus = [JetpackSiteRef: RewindStatus]()
    var fetchingRewindStatus = [JetpackSiteRef: Bool]()

    // This needs to be `fileprivate` because `DelayStateWrapper` is private.
    fileprivate var rewindStatusRetries = [JetpackSiteRef: DelayStateWrapper]()
}

private struct DelayStateWrapper {
    let actionBlock: () -> Void

    var delayCounter = IncrementalDelay(Constants.delaySequence)
    var retryAttempt: Int
    var delayedRetryAction: DispatchDelayedAction

    init(actionBlock: @escaping () -> Void) {
        self.actionBlock = actionBlock
        self.retryAttempt = 0
        self.delayedRetryAction = DispatchDelayedAction(delay: .seconds(delayCounter.current), action: actionBlock)
    }

    mutating func increment() {
        delayCounter.increment()
        delayedRetryAction.cancel()

        retryAttempt += 1
        delayedRetryAction = DispatchDelayedAction(delay: .seconds(delayCounter.current), action: actionBlock)
    }
}

private enum Constants {
    /// Sequence of increasing delays to apply to the fetch restore status mechanism (in seconds)
    static let delaySequence = [1, 5]
    static let maxRetries = 12
}

class ActivityStore: QueryStore<ActivityStoreState, ActivityQuery> {

    fileprivate let refreshInterval: TimeInterval = 60 // seconds

    override func queriesChanged() {
        super.queriesChanged()
        processQueries()
    }

    init() {
        super.init(initialState: ActivityStoreState())
    }

    override func logError(_ error: String) {
        DDLogError(error)
    }

    func processQueries() {
        guard !activeQueries.isEmpty else {
            transaction { state in
                state.activities = [:]
                state.rewindStatus = [:]
                state.rewindStatusRetries = [:]
                state.lastFetch = [:]
                state.fetchingActivities = [:]
                state.fetchingRewindStatus = [:]
            }
            return
        }

        // Fetching Activities.
        sitesToFetch
            .forEach { fetchActivities(site: $0) }


        // Fetching Status
        activeQueries.filter {
            if case .restoreStatus = $0 {
                return true
            } else {
                return false
            }
        }
        .compactMap { $0.site }
        .filter { state.fetchingRewindStatus[$0] != true }
        .unique
        .forEach {
            fetchRewindStatus(site: $0)
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

    func shouldFetch(site: JetpackSiteRef) -> Bool {
        let lastFetch = state.lastFetch[site, default: .distantPast]
        let needsRefresh = lastFetch + refreshInterval < Date()
        let currentlyFetching = isFetching(site: site)
        return needsRefresh && !currentlyFetching
    }

    func isFetching(site: JetpackSiteRef) -> Bool {
        return state.fetchingActivities[site, default: false]
    }

    override func onDispatch(_ action: Action) {
        guard let activityAction = action as? ActivityAction else {
            return
        }

        switch activityAction {
        case .receiveActivities(let site, let activities):
            receiveActivities(site: site, activities: activities)
        case .receiveActivitiesFailed(let site, let error):
            receiveActivitiesFailed(site: site, error: error)
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

            let notice = Notice(title: NSLocalizedString("Your restore is taking longer than usual, please check again in a few minutes.",
                                                         comment: "Text displayed when a site restore takes too long."))
            actionDispatcher.dispatch(NoticeAction.post(notice))
        }
    }
}
// MARK: - Selectors
extension ActivityStore {
    func getActivities(site: JetpackSiteRef) -> [Activity]? {
        return state.activities[site] ?? nil
    }

    func getActivity(site: JetpackSiteRef, rewindID: String) -> Activity? {
        return getActivities(site: site)?.filter { $0.rewindID == rewindID }.first
    }

    func getRewindStatus(site: JetpackSiteRef) -> RewindStatus? {
        return state.rewindStatus[site] ?? nil
    }
}

private extension ActivityStore {
    func fetchActivities(site: JetpackSiteRef, count: Int = 1000) {
        state.fetchingActivities[site] = true

        remote(site: site)?.getActivityForSite(
            site.siteID,
            count: count,
            success: { [actionDispatcher] (activities, _ /* hasMore */) in
                actionDispatcher.dispatch(ActivityAction.receiveActivities(site: site, activities: activities))
        },
            failure: { [actionDispatcher] error in
                actionDispatcher.dispatch(ActivityAction.receiveActivitiesFailed(site: site, error: error))
        })
    }

    func receiveActivities(site: JetpackSiteRef, activities: [Activity]) {
        transaction { state in
            state.activities[site] = activities
            state.fetchingActivities[site] = false
            state.lastFetch[site] = Date()
        }
    }

    func receiveActivitiesFailed(site: JetpackSiteRef, error: Error) {
        transaction { state in
            state.fetchingActivities[site] = false
            state.lastFetch[site] = Date()
        }
    }

    func rewind(site: JetpackSiteRef, rewindID: String) {
        remote(site: site)?.restoreSite(
            site.siteID,
            rewindID: rewindID,
            success: { [actionDispatcher] restoreID in
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
                                      comment: "Title of a message displayed when user starts a rewind operation")

        if let activity = getActivity(site: site, rewindID: rewindID) {
            let formattedString = mediumString(from: activity.published, adjustingTimezoneTo: site)

            let message = String(format: NSLocalizedString("Rewinding to %@", comment: "Notice showing the date the site is being rewinded to. '%@' is a placeholder that will expand to a date."), formattedString)
            notice = Notice(title: title, message: message)
        } else {
            notice = Notice(title: title)
        }

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

            let message = String(format: NSLocalizedString("Rewound to %@", comment: "Notice showing the date the site is being rewinded to. '%@' is a placeholder that will expand to a date."), formattedString)
            notice = Notice(title: title, message: message)
        } else {
            notice = Notice(title: title)
        }

        actionDispatcher.dispatch(NoticeAction.post(notice))
    }

    func rewindFailed(site: JetpackSiteRef, error: Error) {
        let message = NSLocalizedString("Unable to restore your site, please try again later or contact support.",
                                        comment: "Text displayed when a site restore fails.")

        let noticeAction = NoticeAction.post(Notice(title: message))

        actionDispatcher.dispatch(noticeAction)
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

    func delayedRetryFetchRewindStatus(site: JetpackSiteRef) {
        // Note: this might look sorta weird, because it appears we're not at any point actually
        // scheduling the rewind, *but*: initiating/`increment`ing the `DelayStateWrapper` has a side-effect
        // of automagically calling the closure after an appropriate amount of time elapses.

        guard var existingWrapper = state.rewindStatusRetries[site] else {
            let newDelayWrapper = DelayStateWrapper { [weak self] in self?.fetchRewindStatus(site: site) }

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

    func rewindStatusUpdated(site: JetpackSiteRef, status: RewindStatus) {
        let shouldPostStateUpdates = getRewindStatus(site: site)?.restore?.status == .running ||
                                     getRewindStatus(site: site)?.restore?.status == .queued
        // The way our API works, if there was a restore event "recently" (for some undefined value of "recently",
        // on the order of magnitude of ~30 minutes or so), it'll be reported back by the API.
        // But if the restore has finished a good while back (e.g. there's also an event in the AL telling us
        // about the restore happening) we don't neccesarily want to display that redundant info to the users.
        // Hence this somewhat dumb hack — if we've gotten updates about a RewindStatus before (which means we have displayed the UI)
        // we're gonna show users "hey, your rewind finished!". But if the only thing we know the restore is
        // that it has finished in a recent past, we don't do anything special.

        state.rewindStatus[site] = status

        guard let restoreStatus = status.restore else {
            return
        }

        switch restoreStatus.status {
        case .running, .queued:
            delayedRetryFetchRewindStatus(site: site)
        case .finished:
            if shouldPostStateUpdates {
                actionDispatcher.dispatch(ActivityAction.rewindFinished(site: site, restoreID: restoreStatus.id))
            }
        case .fail:
            if shouldPostStateUpdates {
                actionDispatcher.dispatch(ActivityAction.rewindFailed(site: site, restoreID: restoreStatus.id))
            }
        }
    }

    // MARK: - Helpers
    func remote(site: JetpackSiteRef) -> ActivityServiceRemote? {
        guard let token = CredentialsService().getOAuthToken(site: site) else {
            return nil
        }
        let api = WordPressComRestApi(oAuthToken: token, userAgent: WPUserAgent.wordPress())

        return ActivityServiceRemote(wordPressComRestApi: api)
    }

    private func mediumString(from date: Date, adjustingTimezoneTo site: JetpackSiteRef) -> String {
        guard let timezone = timeZone(for: site) else {
            return date.mediumStringWithTime()
        }

        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = timezone

        return formatter.string(from: date)
    }

    private func timeZone(for site: JetpackSiteRef) -> TimeZone? {
        let context = ContextManager.sharedInstance().mainContext
        let blogService = BlogService(managedObjectContext: context)

        guard let blog = blogService.blog(byBlogId: site.siteID as NSNumber) else {
            return TimeZone(secondsFromGMT: 0)
        }

        return blogService.timeZone(for: blog)
    }
}
