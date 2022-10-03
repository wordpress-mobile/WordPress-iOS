import Foundation

struct CoreDataQuery<Result: NSManagedObject> {
    private var predicates = [NSPredicate]()
    private var sortDescriptors = [NSSortDescriptor]()

    private var includesSubentities: Bool = true

    init() {
    }

    func ascending(by key: String) -> Self {
        var query = self
        query.sortDescriptors.append(NSSortDescriptor(key: key, ascending: true))
        return query
    }

    func descending(by key: String) -> Self {
        var query = self
        query.sortDescriptors.append(NSSortDescriptor(key: key, ascending: false))
        return query
    }

    func includesSubentities(_ value: Bool) -> Self {
        var query = self
        query.includesSubentities = value
        return query
    }

    func count(in context: NSManagedObjectContext) -> Int {
        (try? context.count(for: buildFetchRequest())) ?? 0
    }

    func first(in context: NSManagedObjectContext) throws -> Result? {
        let request = buildFetchRequest()
        request.fetchLimit = 1
        return (try context.fetch(request).first)
    }

    func result(in context: NSManagedObjectContext) throws -> [Result] {
        try context.fetch(buildFetchRequest())
    }

    private func buildFetchRequest() -> NSFetchRequest<Result> {
        let request = NSFetchRequest<Result>(entityName: Result.entityName())
        request.includesSubentities = includesSubentities
        request.sortDescriptors = sortDescriptors
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return request
    }

    func and(_ predicate: NSPredicate) -> Self {
        var query = self
        query.predicates.append(predicate)
        return query
    }
}

extension CoreDataQuery {
    private func compare<Value>(_ keyPath: KeyPath<Result, Value>, type: NSComparisonPredicate.Operator, _ value: Value?, options: NSComparisonPredicate.Options = []) -> Self {
        and(
            NSComparisonPredicate(
                leftExpression: NSExpression(forKeyPath: keyPath),
                rightExpression: NSExpression(forConstantValue: value),
                modifier: .direct,
                type: type,
                options: options
            )
        )
    }

    func contains<Value>(_ keyPath: KeyPath<Result, Value>, _ value: Value) -> Self {
        compare(keyPath, type: .contains, value)
    }

    func equal<Value>(_ keyPath: KeyPath<Result, Value>, _ value: Value) -> Self {
        compare(keyPath, type: .equalTo, value)
    }

    func null<Value>(_ keyPath: KeyPath<Result, Value>) -> Self {
        compare(keyPath, type: .equalTo, nil)
    }

    func notNull<Value>(_ keyPath: KeyPath<Result, Value>) -> Self {
        compare(keyPath, type: .notEqualTo, nil)
    }

    func order<Value>(by keyPath: KeyPath<Result, Value>, ascending: Bool = true) -> Self {
        let property = NSExpression(forKeyPath: keyPath).keyPath
        return ascending ? self.ascending(by: property) : self.descending(by: property)
    }
}

protocol CoreDataQueryable {
    associatedtype CoreDataQueryResult: NSManagedObject

    static func query() -> CoreDataQuery<CoreDataQueryResult>
}

extension NSManagedObject: CoreDataQueryable {}

extension CoreDataQueryable where Self: NSManagedObject {
    static func query() -> CoreDataQuery<Self> {
        return CoreDataQuery<Self>()
    }
}

extension CoreDataQuery where Result == Blog {

    static func `default`() -> CoreDataQuery<Blog> {
        Blog.query().order(by: \.settings?.name).includesSubentities(false)
    }

    func blogID(_ id: Int) -> Self {
        blogID(id as NSNumber)
    }

    func blogID(_ id: NSNumber) -> Self {
        equal(\.blogID, id)
    }

    func blogID(_ id: Int64) -> Self {
        blogID(id as NSNumber)
    }

    func username(_ username: String) -> Self {
        equal(\.account?.username, username)
    }

    func hostname(containing hostname: String) -> Self {
        contains(\.url, hostname)
    }

    func hostname(matching hostname: String) -> Self {
        equal(\.url, hostname)
    }

    func visible(_ flag: Bool) -> Self {
        equal(\.visible, flag)
    }

    func hostedByWPCom(_ flag: Bool) -> Self {
        flag ? notNull(\.account) : null(\.account)
    }

}
