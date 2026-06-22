import WordPressData
import WordPressKit
import WordPressShared

/// dependency container for the What's New / Feature Announcements scene
extension RootViewCoordinator {

    @objc func presentWhatIsNew(on viewController: UIViewController) {

        DispatchQueue.main.async { [weak viewController] in
            guard let viewController else {
                return
            }
            self.whatIsNewScenePresenter.present(on: viewController, animated: true, completion: nil)
        }
    }

    @objc func makeWhatIsNewPresenter() -> ScenePresenter {
        WhatIsNewScenePresenter(store: makeAnnouncementStore())
    }

    private func makeAnnouncementStore() -> AnnouncementsStore {
        CachedAnnouncementsStore(cache: makeCache(), service: makeAnnouncementsService())
    }

    private func makeAnnouncementsService() -> AnnouncementServiceRemote {
        AnnouncementServiceRemote(wordPressComRestApi: makeApi())
    }

    private func makeCache() -> AnnouncementsCache {
        UserDefaultsAnnouncementsCache()
    }

    private func makeApi() -> WordPressComRestApi {
        let defaultAccount = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
        let token: String? = defaultAccount?.authToken

        return WordPressComRestApi.defaultApi(
            oAuthToken: token,
            userAgent: WPUserAgent.wordPress(),
            localeKey: WordPressComRestApi.LocaleKeyV2
        )
    }
}
