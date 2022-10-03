import Foundation

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

    func username(_ username: String) -> Self {
        and(NSPredicate(format: "account.username = %@", username))
    }

    func hostname(containing hostname: String) -> Self {
        and(NSPredicate(format: "url CONTAINS %@", hostname))
    }

    func hostname(matching hostname: String) -> Self {
        and(NSPredicate(format: "url = %@", hostname))
    }

    func visible(_ flag: Bool) -> Self {
        and(NSPredicate(format: "visible = %@", NSNumber(booleanLiteral: flag)))
    }

    func hostedByWPCom(_ flag: Bool) -> Self {
        and(NSPredicate(format: flag ? "account != NULL" : "account == NULL"))
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
