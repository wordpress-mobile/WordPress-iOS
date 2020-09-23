import WordPressFlux
import WordPressKit

/// Genric type that renders announcements upon requesting them by calling `getAnnouncements()`
protocol AnnouncementsStore: Observable {
    var announcements: [WordPressKit.Announcement] { get }
    var announcementsVersionHasChanged: Bool { get }
    func getAnnouncements()
    func updateAnnouncementsVersion()
}


/// Announcement store with a local cache of "some sort"
class CachedAnnouncementsStore: AnnouncementsStore {

    private let api: WordPressComRestApi
    private var cache: AnnouncementsCache

    let changeDispatcher = Dispatcher<Void>()

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

    init(cache: AnnouncementsCache, api: WordPressComRestApi) {
        self.cache = cache
        self.api = api
    }

    func getAnnouncements() {

        guard !state.isLoading else {
            return
        }

        state = .loading
        if let announcements = cache.announcements {
            state = .ready(announcements)
            return
        }
        let service = AnnouncementServiceRemote(wordPressComRestApi: api)
        service.getAnnouncements(appId: Identifiers.appId,
                                 appVersion: Identifiers.appVersion,
                                 locale: Locale.current.identifier) { [weak self] result in

            switch result {
            case .success(let announcements):
                DispatchQueue.global().async {
                    self?.cache.announcements = announcements
                }
                self?.state = .ready(announcements)
            case .failure(let error):
                self?.state = .error(error)
            }
        }
    }

    var announcementsVersionHasChanged: Bool {
        UserDefaults.standard.lastKnownAnnouncementsVersion != nil &&
            Bundle.main.shortVersionString() != nil &&
            UserDefaults.standard.lastKnownAnnouncementsVersion != Bundle.main.shortVersionString()
    }

    func updateAnnouncementsVersion() {
        if let newVersion = Bundle.main.shortVersionString() {
            UserDefaults.standard.lastKnownAnnouncementsVersion = newVersion
        }
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


private extension UserDefaults {

    static let lastKnownAnnouncementsVersionKey = "lastKnownAnnouncementsVersion"

    var lastKnownAnnouncementsVersion: String? {
        get {
            string(forKey: UserDefaults.lastKnownAnnouncementsVersionKey)
        }
        set {
            set(newValue, forKey: UserDefaults.lastKnownAnnouncementsVersionKey)
        }
    }
}
