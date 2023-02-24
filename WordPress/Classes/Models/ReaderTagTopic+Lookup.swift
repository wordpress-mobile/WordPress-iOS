import Foundation

extension ReaderTagTopic {

    /// Find an existing topic with the specified slug.
    ///
    /// - Parameter slug: The slug of the topic to find in core data.
    /// - Returns: A matching `ReaderTagTopic` instance or nil.
    static func lookup(withSlug slug: String, in context: NSManagedObjectContext) throws -> ReaderTagTopic? {
        let request = NSFetchRequest<ReaderTagTopic>(entityName: ReaderTagTopic.classNameWithoutNamespaces())
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "slug = %@", slug)
        request.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true)
        ]
        return try context.fetch(request).first
    }

    /// Find an existing topic with the specified slug.
    ///
    /// - Parameter slug: The slug of the topic to find in core data.
    /// - Returns: A matching `ReaderTagTopic` instance or nil.
    @objc(lookupWithSlug:inContext:)
    static func objc_lookup(withSlug slug: String, in context: NSManagedObjectContext) -> ReaderTagTopic? {
        try? lookup(withSlug: slug, in: context)
    }

    /// Find an existing topic with the specified topicID.
    ///
    /// - Parameter tagID: The tag id of the topic to find in core data.
    /// - Returns: A matching `ReaderTagTopic` instance or nil.
    static func lookup(withTagID tagID: NSNumber, in context: NSManagedObjectContext) throws -> ReaderTagTopic? {
        let request = NSFetchRequest<ReaderTagTopic>(entityName: ReaderTagTopic.classNameWithoutNamespaces())
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "tagID = %@", tagID)
        request.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true)
        ]
        return try context.fetch(request).first
    }

    /// Find an existing topic with the specified topicID.
    ///
    /// - Parameter tagID: The tag id of the topic to find in core data.
    /// - Returns: A matching `ReaderTagTopic` instance or nil.
    @objc(lookupWithTagID:inContext:)
    static func objc_lookup(withTagID tagID: NSNumber, in context: NSManagedObjectContext) -> ReaderTagTopic? {
        try? lookup(withTagID: tagID, in: context)
    }

}
