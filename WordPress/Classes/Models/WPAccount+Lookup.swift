import CoreData

public extension WPAccount {

    /// Is this `WPAccount` instance the default WordPress.com account?
    @objc
    var isDefaultWordPressComAccount: Bool {
        guard let uuid = WPAccount.defaultDotComAccountUUID, uuid.count > 0 else {
            return false
        }

        return self.uuid == uuid
    }

    @objc
    var hasBlogs: Bool {
        return !blogs.isEmpty
    }

    /// An Objective-C wrapper around the `lookupDefaultWordPressComAccount` method.
    ///
    /// Prefer using `lookupDefaultWordPressComAccount` directly
    @objc(lookupDefaultWordPressComAccountInContext:)
    static func objc_lookupDefaultWordPressComAccount(in context: NSManagedObjectContext) -> WPAccount? {
        return try? lookupDefaultWordPressComAccount(in: context)
    }

    /// Returns the default WordPress.com account
    /// The default WordPress.com account is the one used for Reader and Notifications
    ///
    /// @return the default WordPress.com account
    /// @see setDefaultWordPressComAccount
    /// @see removeDefaultWordPressComAccount
    static func lookupDefaultWordPressComAccount(in context: NSManagedObjectContext) throws -> WPAccount? {
        guard let uuid = defaultDotComAccountUUID, uuid.count > 0 else {
            // No account, or no default account set. Clear the defaults key.
            defaultDotComAccountUUID = nil
            return nil
        }

        return try lookup(withUUIDString: uuid, in: context)
    }

    static func lookupHasDefaultWordPressComAccount(in context: NSManagedObjectContext) throws -> Bool {
        return try lookupDefaultWordPressComAccount(in: context) != nil
    }

    static func lookup(withUUIDString uuidString: String, in context: NSManagedObjectContext) throws -> WPAccount? {
        let fetchRequest = NSFetchRequest<Self>(entityName: WPAccount.entityName())
        fetchRequest.predicate = NSPredicate(format: "uuid = %@", uuidString)

        guard let defaultAccount = try context.fetch(fetchRequest).first else {
            return nil
        }

        /// This was brought over from the `AccountService`, but can (and probably should) be moved to an accessor for the property
        if let displayName = defaultAccount.displayName {
            defaultAccount.displayName = displayName.stringByDecodingXMLCharacters()
        }

        return defaultAccount
    }

    /// An Objective-C wrapper around the `lookupDefaultWordPressComAccount` method.
    ///
    /// Prefer using `lookupDefaultWordPressComAccount` directly
    @objc(lookupNumberOfAccountsInContext:)
    static func objc_lookupNumberOfAccounts(in context: NSManagedObjectContext) -> Int {
        return (try? lookupNumberOfAccounts(in: context)) ?? 0
    }

    static func lookupNumberOfAccounts(in context: NSManagedObjectContext) throws -> Int {
        let fetchRequest = NSFetchRequest<Self>(entityName: WPAccount.entityName())
        fetchRequest.includesSubentities = false
        return try context.count(for: fetchRequest)
    }

    private static let DefaultDotcomAccountUUIDDefaultsKey = "AccountDefaultDotcomUUID"

    private static var defaultDotComAccountUUID: String? {
        get {
            return UserDefaults.standard.string(forKey: DefaultDotcomAccountUUIDDefaultsKey)
        }
        set {
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: DefaultDotcomAccountUUIDDefaultsKey)
            } else {
                UserDefaults.standard.setValue(newValue, forKey: DefaultDotcomAccountUUIDDefaultsKey)
            }
        }
    }
}
