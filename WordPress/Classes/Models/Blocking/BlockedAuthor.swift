import Foundation

@objc(BlockedAuthor)
final class BlockedAuthor: NSManagedObject {

    @NSManaged var accountID: NSNumber
    @NSManaged var authorID: NSNumber
}

extension BlockedAuthor {

    // MARK: Fetch Elements

    static func findOne(_ query: Query, context: NSManagedObjectContext) -> BlockedAuthor? {
        return Self.find(query, context: context).first
    }

    static func find(_ query: Query, context: NSManagedObjectContext) -> [BlockedAuthor] {
        do {
            let request = NSFetchRequest<BlockedAuthor>(entityName: Self.entityName())
            request.predicate = query.predicate
            let result = try context.fetch(request)
            return result
        } catch let error {
            DDLogError("Couldn't fetch blocked author with error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: Inserting Elements

    static func insert(into context: NSManagedObjectContext) -> BlockedAuthor {
        return NSEntityDescription.insertNewObject(forEntityName: Self.entityName(), into: context) as! BlockedAuthor
    }

    // MARK: - Deleting Elements

    @discardableResult
    static func delete(_ query: Query, context: NSManagedObjectContext) -> Bool {
        let objects = Self.find(query, context: context)
        for object in objects {
            context.deleteObject(object)
        }
        return true
    }

    // MARK: - Types

    enum Query {
        case accountID(NSNumber)
        case predicate(NSPredicate)

        var predicate: NSPredicate {
            switch self {
            case .accountID(let id):
                return NSPredicate(format: "\(#keyPath(BlockedAuthor.accountID)) = %@", id)
            case .predicate(let predicate):
                return predicate
            }
        }
    }
}
