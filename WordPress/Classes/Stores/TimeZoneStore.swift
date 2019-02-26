import WordPressFlux
import WordPressKit

struct TimeZoneQuery {}

enum TimeZoneStoreState {
    case empty
    case loading
    case loaded([TimeZoneGroup])
    case error(Error)

    var shouldFetch: Bool {
        switch self {
        case .loaded:
            return false
        default:
            return true
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
        NotificationCenter.default.addObserver(self, selector: #selector(TimeZoneStore.handleMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    override func queriesChanged() {
        guard !activeQueries.isEmpty && state.shouldFetch else {
            return
        }
        fetchTimeZones()
    }

    @objc func handleMemoryWarning() {
        guard case .loaded = state, activeQueries.isEmpty else {
            return
        }
        state = .empty
    }
}

private extension TimeZoneStore {
    func fetchTimeZones() {
        state = .loading

        let api = WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress(), localeKey: WordPressComRestApi.LocaleKeyV2)

        let remote = TimeZoneServiceRemote(wordPressComRestApi: api)
        remote.getTimezones(
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
