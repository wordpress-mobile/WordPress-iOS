import UIKit

extension MeHeaderView {

    func update(with configuration: Configuration) {
        self.gravatarEmail = configuration.gravatarEmail
        self.username = configuration.username
        self.displayName = configuration.displayName
    }

    struct Configuration {
        let gravatarEmail: String?
        let username: String
        let displayName: String
    }
}

extension MeHeaderView.Configuration {

    init(account: WPAccount) {
        self.init(
            gravatarEmail: account.email,
            username: account.username,
            displayName: account.displayName
        )
    }
}
