import Foundation

extension ReaderSiteTopic {

    /// Find a site topic by its site id
    ///
    /// - Parameter siteID: The site id of the topic
    static func lookup(withSiteID siteID: NSNumber, in context: NSManagedObjectContext) throws -> ReaderSiteTopic? {
        let request = NSFetchRequest<ReaderSiteTopic>(entityName: ReaderSiteTopic.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "siteID = %@", siteID)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// Find a site topic by its site id
    ///
    /// - Parameter siteID: The site id of the topic
    @objc(lookupWithSiteID:inContext:)
    static func objc_lookup(withSiteID siteID: NSNumber, in context: NSManagedObjectContext) -> ReaderSiteTopic? {
        try? lookup(withSiteID: siteID, in: context)
    }

    /// Find a site topic by its feed id
    ///
    /// - Parameter feedID: The feed id of the topic
    static func lookup(withFeedID feedID: NSNumber, in context: NSManagedObjectContext) throws -> ReaderSiteTopic? {
        let request = NSFetchRequest<ReaderSiteTopic>(entityName: ReaderSiteTopic.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "feedID = %@", feedID)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// Find a site topic by its feed id
    ///
    /// - Parameter feedID: The feed id of the topic
    @objc(lookupWithFeedID:inContext:)
    static func objc_lookup(withFeedID feedID: NSNumber, in context: NSManagedObjectContext) -> ReaderSiteTopic? {
        try? lookup(withFeedID: feedID, in: context)
    }

    /// Find a site topic by its feed URL
    ///
    /// - Parameter feedURL: The feed URL of the topic
    static func lookup(withFeedURL feedURL: String, in context: NSManagedObjectContext) throws -> ReaderSiteTopic? {
        let request = NSFetchRequest<ReaderSiteTopic>(entityName: ReaderSiteTopic.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "feedURL = %@", feedURL)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// Find a site topic by its feed URL
    ///
    /// - Parameter feedURL: The feed URL of the topic
    @objc(lookupWithFeedURL:inContext:)
    static func objc_lookup(withFeedURL feedURL: String, in context: NSManagedObjectContext) -> ReaderSiteTopic? {
        try? lookup(withFeedURL: feedURL, in: context)
    }
}
