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

}
