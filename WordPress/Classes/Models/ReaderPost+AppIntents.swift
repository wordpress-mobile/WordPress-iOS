import Foundation
import WordPressData

extension ReaderPost {
    /// The parsed components of a reader post App Intent entity identifier
    /// (`readerPost|~~~|<siteID>|~~~|<postID>`), shared by the Core Data
    /// resolver and the placeholder entities that represent posts missing
    /// from the local store.
    struct AppIntentIdentifier {
        let siteID: Int
        let postID: Int

        init?(identifier: String) {
            guard let (itemType, domain, postIDString) = SearchIdentifierGenerator.decomposeFromUniqueIdentifier(identifier),
                itemType == .readerPost,
                let siteID = Int(domain),
                let postID = Int(postIDString)
            else {
                return nil
            }
            self.siteID = siteID
            self.postID = postID
        }
    }

    /// Resolves the reader post an App Intent entity identifier refers to.
    ///
    /// The identifier is the same composite string the Spotlight index uses
    /// (`readerPost|~~~|<siteID>|~~~|<postID>`). An identifier that cannot be
    /// resolved returns `nil` rather than falling back to another post.
    static func forAppIntent(identifier: String, in context: NSManagedObjectContext) -> ReaderPost? {
        guard let identifier = AppIntentIdentifier(identifier: identifier) else {
            return nil
        }

        return try? ReaderPost.lookup(
            withID: NSNumber(value: identifier.postID),
            forSiteWithID: NSNumber(value: identifier.siteID),
            in: context
        )
    }

    /// Returns reader posts an App Intent entity query can offer, newest
    /// first. An empty query returns the most recent posts. Only posts that
    /// can be identified by `forAppIntent(identifier:in:)` are returned.
    static func searchForAppIntent(
        matching query: String,
        limit: Int = 20,
        in context: NSManagedObjectContext
    ) -> [ReaderPost] {
        let request = NSFetchRequest<ReaderPost>(entityName: ReaderPost.classNameWithoutNamespaces())
        var predicates = [NSPredicate(format: "postID > 0 AND siteID > 0")]
        if !query.isEmpty {
            predicates.append(NSPredicate(format: "postTitle CONTAINS[cd] %@", query))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(ReaderPost.sortDate), ascending: false)]
        request.fetchLimit = limit
        let posts = (try? context.fetch(request)) ?? []
        // The same remote post is cached once per Reader topic; keep only the
        // first (newest) row for each site/post pair so the entity ids stay
        // unique.
        var seen = Set<String>()
        return posts.filter { post in
            guard let identifier = post.uniqueIdentifier else {
                return false
            }
            return seen.insert(identifier).inserted
        }
    }
}
