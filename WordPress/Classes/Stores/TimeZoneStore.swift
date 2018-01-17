import WordPressFlux
import WordPressKit

struct TimeZoneQuery {}

enum TimeZoneStoreState {
    case empty
    case loading
    case loaded([TimeZoneGroup])
    case error(Error)

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    var groups: [TimeZoneGroup] {
        switch self {
        case .loaded(let groups):
            return groups
        default:
            return []
        }
    }

    var allTimezones: [WPTimeZone] {
        return groups.flatMap({ $0.timezones })
    }

    func findTimezone(gmtOffset: Float?, timezoneString: String?) -> WPTimeZone? {
        // Try to find a matching timezone with timezoneString
        return timezoneString
            .flatMap({ findTimezone(value: $0) })
            // If that doesn't work, parse gmtOffset with OffsetTimeZone and
            // use that to search
            ?? gmtOffset
                .map(OffsetTimeZone.init)
                .flatMap({ findTimezone(value: $0.value) })
    }

    private func findTimezone(value: String) -> WPTimeZone? {
        return allTimezones.first(where: { $0.value == value })
    }
}

class TimeZoneStore: QueryStore<TimeZoneStoreState, TimeZoneQuery> {
    init(dispatcher: ActionDispatcher = .global) {
        super.init(initialState: .empty, dispatcher: dispatcher)
    }

    override func queriesChanged() {
        guard !activeQueries.isEmpty && !state.isLoading else {
            return
        }
        fetchTimeZones()
    }
}

private extension TimeZoneStore {
    func fetchTimeZones() {
        state = .loading
        let remote = TimeZoneServiceRemote(wordPressComRestApi: .anonymousApi(userAgent: WPUserAgent.wordPress()))
        remote?.getTimezones(
            success: { [weak self] (groups) in
                self?.state = .loaded(groups)
            },
            failure: { [weak self] (error) in
                DDLogError("Error loading timezones: \(error)")
                self?.state = .error(error)
            }
        )
    }
}
