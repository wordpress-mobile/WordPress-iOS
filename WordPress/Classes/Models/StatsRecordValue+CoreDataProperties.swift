import Foundation
import CoreData


extension StatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StatsRecordValue> {
        return NSFetchRequest<StatsRecordValue>(entityName: "StatsRecordValue")
    }

    @NSManaged public var statsRecord: StatsRecord?

}
