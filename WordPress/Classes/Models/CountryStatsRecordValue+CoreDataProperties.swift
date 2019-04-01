import Foundation
import CoreData


extension CountryStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CountryStatsRecordValue> {
        return NSFetchRequest<CountryStatsRecordValue>(entityName: "CountryStatsRecordValue")
    }

    @NSManaged public var countryCode: String?
    @NSManaged public var countryName: String?
    @NSManaged public var viewsCount: Int64

}
