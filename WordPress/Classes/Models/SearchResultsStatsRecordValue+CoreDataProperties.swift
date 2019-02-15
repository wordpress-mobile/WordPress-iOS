import Foundation
import CoreData


extension SearchResultsStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SearchResultsStatsRecordValue> {
        return NSFetchRequest<SearchResultsStatsRecordValue>(entityName: "SearchResultsStatsRecordValue")
    }

    @NSManaged public var viewsCount: Int64
    @NSManaged public var searchTerm: String?

}
