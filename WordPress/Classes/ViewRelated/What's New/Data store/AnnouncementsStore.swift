import WordPressFlux
import WordPressKit

/// Genric type that renders announcements upon requesting them by calling `getAnnouncements()`
protocol AnnouncementsStore: Observable {
    var announcements: [WordPressKit.Announcement] { get }
    func getAnnouncements()
}


/// Announcement store with a local cache of "some sort"
class CachedAnnouncementsStore: AnnouncementsStore {

    let changeDispatcher = Dispatcher<Void>()

    var cache: AnnouncementsCache

    enum State {
        case loading
        case ready([WordPressKit.Announcement])
        case error(Error)

        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            case .error, .ready:
                return false
            }
        }
    }

    var state: State = .ready([]) {
        didSet {
            guard !state.isLoading else {
                return
            }
            emitChange()
        }
    }

    var announcements: [WordPressKit.Announcement] {
        switch state {
        case .loading, .error:
            return []
        case .ready(let announcements):
            return announcements
        }
    }

    init(cache: AnnouncementsCache) {
        self.cache = cache
    }

    func getAnnouncements() {
        state = .loading
        if let announcements = cache.announcements {
            self.state = .ready(announcements)
            return
        }

        let service = AnnouncementServiceRemote(wordPressComRestApi: api)
        service.getAnnouncements(appId: Identifiers.appId,
                                 appVersion: Identifiers.appVersion,
                                 locale: Locale.current.identifier) { result in

            switch result {
            case .success(let announcements):
                self.state = .ready(announcements)
                self.cache.announcements = announcements
            case .failure(let error):
                self.state = .error(error)
            }
        }
    }

    private var api: WordPressComRestApi {
        let accountService = AccountService(managedObjectContext: CoreDataManager.shared.mainContext)
        let defaultAccount = accountService.defaultWordPressComAccount()
        let token: String? = defaultAccount?.authToken

        return WordPressComRestApi.defaultApi(oAuthToken: token,
                                              userAgent: WPUserAgent.wordPress(),
                                              localeKey: WordPressComRestApi.LocaleKeyV2)
    }
}


private extension CachedAnnouncementsStore {
    enum Identifiers {
        // 2 is the identifier of WordPress-iOS in the backend
        static let appId = "2"
        static var appVersion: String {
            Bundle.main.shortVersionString() ?? ""
        }
    }
}
