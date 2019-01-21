import Foundation
import WordPressFlux
import WordPressComStatsiOS

enum PeriodAction: Action {

}

enum PeriodQuery {
    case periods
}

struct PeriodStoreState {

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
        default:
            break
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

    var isFetching: Bool {
        return true
    }

}
