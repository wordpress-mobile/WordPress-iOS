import CoreData

public extension WPAccount {

    // MARK: - Relationship Lookups

    /// Is this `WPAccount` object the default WordPress.com account?
    ///
    @objc
    var isDefaultWordPressComAccount: Bool {
        guard let uuid = UserSettings.defaultDotComUUID, uuid.count > 0 else {
            return false
        }

        return self.uuid == uuid
    }

    /// Does this `WPAccount` object have any associated blogs?
    ///
    @objc
    var hasBlogs: Bool {
        return !blogs.isEmpty
    }

    // MARK: - Object Lookups

    /// Returns the default WordPress.com account, if one exists
    ///
    /// The default WordPress.com account is the one used for Reader and Notifications.
    ///
    static func lookupDefaultWordPressComAccount(in context: NSManagedObjectContext) throws -> WPAccount? {
        guard let uuid = UserSettings.defaultDotComUUID, uuid.count > 0 else {
            // No account, or no default account set. Clear the defaults key.
            UserSettings.defaultDotComUUID = nil
            return nil
        }

        return try lookup(withUUIDString: uuid, in: context)
    }

    /// Does a default WordPress.com account exist?
    /// The default WordPress.com account is the one used for Reader and Notifications.
    ///
    static func lookupHasDefaultWordPressComAccount(in context: NSManagedObjectContext) throws -> Bool {
        return try lookupDefaultWordPressComAccount(in: context) != nil
    }

    /// Lookup a WPAccount by its local uuid
    ///
    /// - Parameters:
    ///   - uuidString: The UUID (in string form) associated with the account
    ///   - context:  An NSManagedObjectContext containing the `WPAccount` object with the given `uuidString`.
    /// - Returns: The `WPAccount` object associated with the given `uuidString`, if it exists.
    ///
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

    /// Lookup the total number of `WPAccount` objects in the given `context`.
    ///
    /// If none exist, this method returns `0`.
    ///
    /// - Parameters:
    ///   - context:  An NSManagedObjectContext that may or may not contain `WPAccount` objects.
    /// - Returns: The number of `WPAccount` objects in the given `context`.
    ///
    static func lookupNumberOfAccounts(in context: NSManagedObjectContext) throws -> Int {
        let fetchRequest = NSFetchRequest<Self>(entityName: WPAccount.entityName())
        fetchRequest.includesSubentities = false
        return try context.count(for: fetchRequest)
    }

    // MARK: - Objective-C Compatibility Wrappers

    /// An Objective-C wrapper around the `lookupDefaultWordPressComAccount` method.
    ///
    /// Prefer using `lookupDefaultWordPressComAccount` directly
    @objc(lookupDefaultWordPressComAccountInContext:)
    static func objc_lookupDefaultWordPressComAccount(in context: NSManagedObjectContext) -> WPAccount? {
        return try? lookupDefaultWordPressComAccount(in: context)
    }

    /// An Objective-C wrapper around the `lookupDefaultWordPressComAccount` method.
    ///
    /// Prefer using `lookupDefaultWordPressComAccount` directly
    @objc(lookupNumberOfAccountsInContext:)
    static func objc_lookupNumberOfAccounts(in context: NSManagedObjectContext) -> Int {
        return (try? lookupNumberOfAccounts(in: context)) ?? 0
    }
}
