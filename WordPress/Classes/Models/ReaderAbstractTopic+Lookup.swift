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

}
