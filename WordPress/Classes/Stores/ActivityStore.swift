import Foundation
import WordPressKit
import WordPressFlux

// MARK: - Store helper types

enum ActivityAction: Action {
    case receiveActivities(site: JetpackSiteRef, activities: [Activity])
    case receiveActivitiesFailed(site: JetpackSiteRef, error: Error)

    case rewind(site: JetpackSiteRef, rewindID: String)
    case rewindStarted(site: JetpackSiteRef, restoreID: String)
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
            if case .restoreStatus = $0 { return true }
            else { return false }
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
                if case .activities = $0 { return true }
                else { return false }
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

    func isRestoring(site: JetpackSiteRef) -> Bool {
        return false
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
        case .rewindStarted(let site, let restoreID):
            rewindStarted(site: site, restoreID: restoreID)
        case .rewindRequestFailed(let site, let error):
            rewindFailed(site: site, error: error)
        case .rewindStatusUpdated(let site, let status):
            rewindStatusUpdated(site: site, status: status)
        case .rewindStatusUpdateFailed(let site, _):
            delayedRetryFetchRewindStatus(site: site)
        case .rewindFinished(let site, _),
             .rewindFailed(let site, _),
             .rewindStatusUpdateTimedOut(let site):
            transaction { state in
                state.fetchingRewindStatus[site] = false
                state.rewindStatusRetries[site] = nil
            }
        }
    }
}
// MARK: - Selectors
extension ActivityStore {
    func getActivities(site: JetpackSiteRef) -> [Activity]? {
        return state.activities[site] ?? nil
    }
    func getRewindStatus(site: JetpackSiteRef) -> RewindStatus? {
        return state.rewindStatus[site] ?? nil
    }
}

private extension ActivityStore {
    func fetchActivities(site: JetpackSiteRef, count: Int = 1000) {
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
                actionDispatcher.dispatch(ActivityAction.rewindStarted(site: site, restoreID: restoreID))
            },
            failure: {  [actionDispatcher] error in
                actionDispatcher.dispatch(ActivityAction.rewindRequestFailed(site: site, error: error))
        })
    }

    func rewindStarted(site: JetpackSiteRef, restoreID: String) {
        fetchRewindStatus(site: site)
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
        state.rewindStatus[site] = status

        guard let restoreStatus = status.restore else {
            return
        }

        switch restoreStatus.status {
        case .running, .queued:
            delayedRetryFetchRewindStatus(site: site)
        case .finished:
            actionDispatcher.dispatch(ActivityAction.rewindFinished(site: site, restoreID: restoreStatus.id))
        case .fail:
            actionDispatcher.dispatch(ActivityAction.rewindFailed(site: site, restoreID: restoreStatus.id))
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
}
