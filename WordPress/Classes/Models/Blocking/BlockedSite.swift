import Foundation

@objc(BlockedSite)
final class BlockedSite: NSManagedObject {

    @NSManaged var accountID: NSNumber
    @NSManaged var blogID: NSNumber
}

extension BlockedSite {

    // MARK: Fetch Elements

    static func findOne(accountID: NSNumber, blogID: NSNumber, context: NSManagedObjectContext) -> BlockedSite? {
        return Self.find(accountID: accountID, blogID: blogID, context: context).first
    }

    static func find(accountID: NSNumber, blogID: NSNumber, context: NSManagedObjectContext) -> [BlockedSite] {
        do {
            let request = NSFetchRequest<BlockedSite>(entityName: Self.entityName())
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "\(#keyPath(BlockedSite.accountID)) = %@ AND \(#keyPath(BlockedSite.blogID)) = %@", accountID, blogID)
            let result = try context.fetch(request)
            return result
        } catch let error {
            DDLogError("Couldn't fetch blocked site with error: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: Inserting Elements

    static func insert(into context: NSManagedObjectContext) -> BlockedSite {
        return NSEntityDescription.insertNewObject(forEntityName: Self.entityName(), into: context) as! BlockedSite
    }

    // MARK: - Deleting Elements

    @discardableResult
    static func delete(accountID: NSNumber, blogID: NSNumber, context: NSManagedObjectContext) -> Bool {
        let objects = Self.find(accountID: accountID, blogID: blogID, context: context)
        for object in objects {
            context.deleteObject(object)
        }
        return true
    }
}


