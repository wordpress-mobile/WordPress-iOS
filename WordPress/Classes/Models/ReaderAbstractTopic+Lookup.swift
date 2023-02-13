import Foundation

extension ReaderAbstractTopic {

    /// Fetch all `ReaderAbstractTopics` currently in Core Data.
    ///
    /// - Returns: An array of all `ReaderAbstractTopics` currently persisted in Core Data.
    @objc(lookupAllInContext:error:)
    static func lookupAll(in context: NSManagedObjectContext) throws -> [ReaderAbstractTopic] {
        let request = NSFetchRequest<ReaderAbstractTopic>(entityName: ReaderAbstractTopic.classNameWithoutNamespaces())
        return try context.fetch(request)
    }

    /// Fetch all `ReaderAbstractTopics` for the menu currently in Core Data.
    ///
    /// - Returns: An array of all `ReaderAbstractTopics` for the menu currently persisted in Core Data.
    @objc(lookupAllMenusInContext:error:)
    static func lookupAllMenus(in context: NSManagedObjectContext) throws -> [ReaderAbstractTopic] {
        let request = NSFetchRequest<ReaderAbstractTopic>(entityName: ReaderAbstractTopic.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "showInMenu = YES")
        return try context.fetch(request)
    }

    /// Fetch all `Fetch all saved Site topics` currently in Core Data.
    ///
    @objc(lookupAllSitesInContext:error:)
    static func lookupAllSites(in context: NSManagedObjectContext) throws -> [ReaderSiteTopic] {
        let request = NSFetchRequest<ReaderSiteTopic>(entityName: ReaderSiteTopic.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "following = YES")
        request.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]
        return try context.fetch(request)
    }

    /// Find a specific ReaderAbstractTopic by its `path` property.
    ///
    /// - Parameter path: The unique, cannonical path of the topic.
    /// - Returns: A matching `ReaderAbstractTopic` or nil if there is no match.
    static func lookup(withPath path: String, in context: NSManagedObjectContext) throws -> ReaderAbstractTopic? {
        let lowcasedPath = path.lowercased()
        return try lookupAll(in: context).first { $0.path == lowcasedPath }
    }

    /// Find a specific ReaderAbstractTopic by its `path` property.
    ///
    /// - Parameter path: The unique, cannonical path of the topic.
    /// - Returns: A matching `ReaderAbstractTopic` or nil if there is no match.
    @objc(lookupWithPath:inContext:)
    static func objc_lookup(withPath path: String, in context: NSManagedObjectContext) -> ReaderAbstractTopic? {
        try? lookup(withPath: path, in: context)
    }

    /// Find a topic where its path contains a specified path.
    ///
    /// - Parameter path: The path of the topic
    /// - Returns: A matching abstract topic or nil.
    static func lookup(pathContaining path: String, in context: NSManagedObjectContext) throws -> ReaderAbstractTopic? {
        let lowcasedPath = path.lowercased()
        return try lookupAll(in: context).first { $0.path.contains(lowcasedPath) }
    }

    /// Find a topic where its path contains a specified path.
    ///
    /// - Parameter path: The path of the topic
    /// - Returns: A matching abstract topic or nil.
    @objc(lookupContainingPath:inContext:)
    static func objc_lookup(pathContaining path: String, in context: NSManagedObjectContext) -> ReaderAbstractTopic? {
        try? lookup(pathContaining: path, in: context)
    }

}
