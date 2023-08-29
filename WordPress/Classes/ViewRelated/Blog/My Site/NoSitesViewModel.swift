import Foundation

struct NoSitesViewModel {
    let displayName: String
    let gravatarURL: URL?

    var isShowingAccountAndSettings: Bool {
        JetpackFeaturesRemovalCoordinator.currentAppUIType == .simplified
    }

    init(account: WPAccount?) {
        self.displayName = account?.displayName ?? "-"
        if let account {
            self.gravatarURL = Gravatar.gravatarUrl(for: account.email)
        } else {
            self.gravatarURL = nil
        }
    }
}
