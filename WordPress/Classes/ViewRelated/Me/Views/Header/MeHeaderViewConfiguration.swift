import UIKit

struct MeHeaderViewConfiguration {

    let gravatarEmail: String?
    let username: String
    let displayName: String
}

extension MeHeaderViewConfiguration {

    init(account: WPAccount) {
        self.init(
            gravatarEmail: account.email,
            username: account.username,
            displayName: account.displayName
        )
    }
}

extension MeHeaderView {

    func update(with configuration: Configuration) {
        self.gravatarEmail = configuration.gravatarEmail
        self.username = configuration.username
        self.displayName = configuration.displayName
    }

    typealias Configuration = MeHeaderViewConfiguration
}
