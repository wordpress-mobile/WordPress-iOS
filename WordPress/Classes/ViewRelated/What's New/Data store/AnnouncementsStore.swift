import WordPressFlux
import WordPressKit

/// Genric type that renders announcements upon requesting them by calling `getAnnouncements()`
protocol AnnouncementsStore: Observable {
    var announcements: [WordPressKit.Announcement] { get }
    func getAnnouncements()
}


class RemoteAnnouncementsStore: AnnouncementsStore {

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

    func getAnnouncements() {
        let service = AnnouncementServiceRemote(wordPressComRestApi: api)
        state = .loading
        service.getAnnouncements(appId: Identifiers.appId,
                                 appVersion: Identifiers.appVersion,
                                 locale: Locale.current.identifier) { result in

            switch result {
            case .success(let announcements):
                self.state = .ready(announcements)
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


private extension RemoteAnnouncementsStore {
    enum Identifiers {
        static let appId = "2"
        static var appVersion: String {
            Bundle.main.shortVersionString() ?? ""
        }
    }
}
