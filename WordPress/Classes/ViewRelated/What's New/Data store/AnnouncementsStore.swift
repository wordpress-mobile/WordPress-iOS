import WordPressFlux
import WordPressKit

/// Genric type that renders announcements upon requesting them by calling `getAnnouncements()`
protocol AnnouncementsStore: Observable {
    var announcements: [WordPressKit.Announcement] { get }
    func getAnnouncements(appId: String, appVersion: String)
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

    func getAnnouncements(appId: String, appVersion: String) {
        let service = AnnouncementServiceRemote(wordPressComRestApi: api)
        state = .loading
        service.getAnnouncements(appId: appId,
                                 appVersion: appVersion,
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


//private extension LocalAnnouncementsStore {
//
//    enum Constants {
//        static let announcements = [Announcement(appId: "3",
//                                                 appVersion: "15.4",
//                                                 minAppVersion: "15.4",
//                                                 maxAppVersion: "15.5",
//                                                 title: NSLocalizedString("Short announcement for 15.4 and 15.5",
//                                                                          comment: "Title for a feature announcement"),
//                                                 message: NSLocalizedString("This is a short announcement that will appear in versions 15.4 and 15.5",
//                                                                            comment: "Description for a feature announcement"),
//                                                 icon: nil,
//                                                 iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-premium.png",
//                                                 detailsUrl: nil,
//                                                 appVersionTargets: nil),
//                                    Announcement(appId: "3",
//                                                 appVersion: "15.4",
//                                                 minAppVersion: "15.4",
//                                                 maxAppVersion: "15.5",
//                                                 title: NSLocalizedString("Long announcement for 15.4 and 15.5",
//                                                                          comment: "Title for a feature announcement"),
//                                                 message: NSLocalizedString("We like long feature announcements that why this one is going to be a bit long and possibly span multiple lines, for versions 15.4 and 15.5",
//                                                                            comment: "Description for a feature announcement"),
//                                                 icon: nil,
//                                                 iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-premium.png",
//                                                 detailsUrl: nil,
//                                                 appVersionTargets: nil),
//                                    Announcement(appId: "3",
//                                                 appVersion: "15.3",
//                                                 minAppVersion: "15.3",
//                                                 maxAppVersion: "15.2",
//                                                 title: NSLocalizedString("Short announcement for 15.2 and 15.3" ,
//                                                                          comment: "Title for a feature announcement"),
//                                                 message: NSLocalizedString("This is a short announcement that will appear in versions 15.2 and 15.3" ,
//                                                                            comment: "Description for a feature announcement"),
//                                                 icon: nil,
//                                                 iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-premium.png",
//                                                 detailsUrl: nil,
//                                                 appVersionTargets: nil),
//                                    Announcement(appId: "3",
//                                                 appVersion: "15.3",
//                                                 minAppVersion: "15.2",
//                                                 maxAppVersion: "15.3",
//                                                 title: NSLocalizedString("Long announcement for 15.2 and 15.3" ,
//                                                                          comment: "Title for a feature announcement"),
//                                                 message: NSLocalizedString("We like long feature announcements that why this one is going to be a bit long and possibly span multiple lines, for versions 15.2 and 15.3",
//                                                                            comment: "Description for a feature announcement"),
//                                                 icon: nil,
//                                                 iconUrl: "https://s0.wordpress.com/i/store/mobile/plans-premium.png",
//                                                 detailsUrl: nil,
//                                                 appVersionTargets: nil)]
//    }
//}
