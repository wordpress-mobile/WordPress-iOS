import Foundation

/// A simple container for the user info shown on the login epilogue screen.
///
struct LoginEpilogueUserInfo {
    var username = ""
    var fullname = ""
    var email = ""
    var gravatarUrl: String?

    init(account: WPAccount) {
        if let name = account.username {
            username = "@\(name)"
        }
        email = account.email
        fullname = account.displayName
    }

    init() {
    }

}
