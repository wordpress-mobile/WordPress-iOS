import Foundation
import CoreData


extension ClicksStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ClicksStatsRecordValue> {
        return NSFetchRequest<ClicksStatsRecordValue>(entityName: "ClicksStatsRecordValue")
    }

    @NSManaged public var clicksCount: Int64
    @NSManaged public var label: String?
    @NSManaged public var countryName: String?
    @NSManaged public var urlString: String?
    @NSManaged public var children: NSSet?
    @NSManaged public var parent: ClicksStatsRecordValue?

}

// MARK: Generated accessors for children
extension ClicksStatsRecordValue {

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: ClicksStatsRecordValue)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: ClicksStatsRecordValue)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSSet)

}
