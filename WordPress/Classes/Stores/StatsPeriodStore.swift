import Foundation
import WordPressFlux
import WordPressComStatsiOS

enum PeriodAction: Action {
    case refreshPeriodData()
}

enum PeriodQuery {
    case periods
}

struct PeriodStoreState {
    var pagesAndPosts: [StatsItem]?
    var fetchingPagesAndPosts = false
}

class StatsPeriodStore: QueryStore<PeriodStoreState, PeriodQuery> {

    init() {
        super.init(initialState: PeriodStoreState())
    }

    override func onDispatch(_ action: Action) {

        guard let periodAction = action as? PeriodAction else {
            return
        }

        switch periodAction {
        case .refreshPeriodData:
            refreshPeriodData()
        }
    }

    override func queriesChanged() {
        super.queriesChanged()
        processQueries()
    }

}

// MARK: - Private Methods

private extension StatsPeriodStore {

    func processQueries() {

        guard !activeQueries.isEmpty && shouldFetch() else {
            return
        }

        fetchPeriodData()
    }

    func fetchPeriodData() {

        // TODO: get some data

    }

    func refreshPeriodData() {
        guard shouldFetch() else {
            DDLogInfo("Stats Period refresh triggered while one was in progress.")
            return
        }

        fetchPeriodData()
    }

    func shouldFetch() -> Bool {
        return !isFetching
    }

}

// MARK: - Public Accessors

extension StatsPeriodStore {

    func getPostsAndPages() -> [StatsItem]? {
        return state.pagesAndPosts
    }

    var isFetching: Bool {
        return state.fetchingPagesAndPosts
    }

}
