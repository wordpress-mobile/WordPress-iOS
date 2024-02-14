import Foundation
import WordPressUI
import Gravatar

struct NoSitesViewModel {

    private var appUIType: RootViewCoordinator.AppUIType?

    let displayName: String
    let gravatarURL: URL?

    var isShowingAccountAndSettings: Bool {
        appUIType == .simplified
    }

    init(appUIType: RootViewCoordinator.AppUIType?, account: WPAccount?) {
        self.appUIType = appUIType
        self.displayName = account?.displayName ?? "-"
        if let email = account?.email {
            self.gravatarURL = GravatarURL.url(for: email)
        } else {
            self.gravatarURL = nil
        }
    }
}
