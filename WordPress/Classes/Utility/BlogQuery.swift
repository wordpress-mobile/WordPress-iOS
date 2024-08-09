import Foundation

/// A helper to query `Blog` from given `NSManagedObjectContext`.
///
/// Note: the implementation here isn't meant to be a standard way to perform query. But it might be valuable
/// to explore a standard way to perform query. https://github.com/wordpress-mobile/WordPress-iOS/pull/19394 made
/// an attempt, but still has lots of unknowns.
struct BlogQuery {
    private var predicates = [NSPredicate]()

    func blogID(_ id: Int) -> Self {
        blogID(Int64(id))
    }

    func blogID(_ id: NSNumber) -> Self {
        blogID(id.int64Value)
    }

    func blogID(_ id: Int64) -> Self {
        and(NSPredicate(format: "blogID = %ld", id))
    }

    func dotComAccountUsername(_ username: String) -> Self {
        and(NSPredicate(format: "account.username = %@", username))
    }

    func selfHostedBlogUsername(_ username: String) -> Self {
        and(NSPredicate(format: "username = %@", username))
    }

    func hostname(containing hostname: String) -> Self {
        and(NSPredicate(format: "url CONTAINS %@", hostname))
    }

    func hostname(matching hostname: String) -> Self {
        and(NSPredicate(format: "url = %@", hostname))
    }

    func hostedByWPCom(_ flag: Bool) -> Self {
        and(NSPredicate(format: flag ? "account != NULL" : "account == NULL"))
    }

    func xmlrpc(matching xmlrpc: String) -> Self {
        and(NSPredicate(format: "xmlrpc = %@", xmlrpc))
    }

    func apiKey(is string: String) -> Self {
        and(NSPredicate(format: "apiKey = %@", string))
    }

    func count(in context: NSManagedObjectContext) -> Int {
        (try? context.count(for: buildFetchRequest())) ?? 0
    }

    func blog(in context: NSManagedObjectContext) throws -> Blog? {
        let request = buildFetchRequest()
        request.fetchLimit = 1
        return (try context.fetch(request).first)
    }

    func blogs(in context: NSManagedObjectContext) throws -> [Blog] {
        try context.fetch(buildFetchRequest())
    }

    private func buildFetchRequest() -> NSFetchRequest<Blog> {
        let request = NSFetchRequest<Blog>(entityName: Blog.entityName())
        request.includesSubentities = false
        request.sortDescriptors = [NSSortDescriptor(key: "settings.name", ascending: true)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return request
    }

    private func and(_ predicate: NSPredicate) -> Self {
        var query = self
        query.predicates.append(predicate)
        return query
    }
}
