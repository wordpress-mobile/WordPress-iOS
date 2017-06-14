import Foundation

/// A simple container for the user info shown on the login epilogue screen.
///
struct LoginEpilogueUserInfo {
    var username = ""
    var fullName = ""
    var email = ""
    var gravatarUrl: String?
    var blog: Blog?

    init(account: WPAccount) {
        if let name = account.username {
            username = name
        }
        email = account.email
        fullName = account.displayName
    }

    init() {
    }

}
