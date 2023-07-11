/// Centralized utility to generate preconfigured WPAccount instances
extension WPAccount {

    static func fixture(
        context: NSManagedObjectContext,
        // Using a constant UUID by default to keep the tests deterministic.
        // There's nothing special in the value itself. It's just a UUID() value copied over.
        uuid: UUID = UUID(uuidString: "D0D0298F-D7EF-4F32-A1F8-DDDBB8ADB8DF")!,
        userID: Int = 1,
        username: String = "username",
        authToken: String = "authToken"
    ) -> WPAccount {
        let account = WPAccount(context: context)
        account.userID = NSNumber(value: userID)
        account.username = username
        account.authToken = authToken
        account.uuid = uuid.uuidString
        return account
    }
}
