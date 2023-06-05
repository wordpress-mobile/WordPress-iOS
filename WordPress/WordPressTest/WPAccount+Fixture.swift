/// Centralized utility to generate preconfigured WPAccount instances
extension WPAccount {

    static func fixture(
        context: NSManagedObjectContext,
        userID: Int = 1,
        username: String = "username",
        authToken: String = "authToken"
    ) -> WPAccount {
        let account = WPAccount(context: context)
        account.userID = NSNumber(value: userID)
        account.username = username
        account.authToken = authToken
        return account
    }
}
