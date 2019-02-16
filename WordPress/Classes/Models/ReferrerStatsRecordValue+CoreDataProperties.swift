
import Foundation
import CoreData


extension ReferrerStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReferrerStatsRecordValue> {
        return NSFetchRequest<ReferrerStatsRecordValue>(entityName: "ReferrerStatsRecordValue")
    }

    @NSManaged public var viewsCount: Int64
    @NSManaged public var iconURLString: String?
    @NSManaged public var label: String?
    @NSManaged public var urlString: String?
    @NSManaged public var children: NSSet?
    @NSManaged public var parent: ReferrerStatsRecordValue?

}

// MARK: Generated accessors for children
extension ReferrerStatsRecordValue {

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: ReferrerStatsRecordValue)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: ReferrerStatsRecordValue)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSSet)

}
