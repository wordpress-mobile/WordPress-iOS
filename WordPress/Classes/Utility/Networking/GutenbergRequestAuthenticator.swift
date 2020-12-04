/// Small override of RequestAuthenticator to be able to authenticate with writting rights on Atomic sites.
/// Needed to load the gutenberg web editor on a web view on Atomic public and private sites.
class GutenbergRequestAuthenticator: RequestAuthenticator {
    convenience init?(account: WPAccount, blog: Blog? = nil) {
        guard
            let username = account.username,
            let token = account.authToken
        else {
            return nil
        }

        // To load gutenberg web editor (or wp-admin in general) we need regular authentication type.
        self.init(credentials: .dotCom(username: username, authToken: token, authenticationType: .regular))
    }
}
