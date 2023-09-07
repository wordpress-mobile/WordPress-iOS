import Foundation

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
        if let account {
            self.gravatarURL = Gravatar.gravatarUrl(for: account.email)
        } else {
            self.gravatarURL = nil
        }
    }
}
