import Foundation
import CoreData


public enum TagsCategoriesType: Int16 {
    case tag
    case category
    case folder
}

public class TagsCategoriesStatsRecordValue: StatsRecordValue {

    public var linkURL: URL? {
        guard let url = urlString as String? else {
            return nil
        }
        return URL(string: url)
    }

    public override func validateForInsert() throws {
        try super.validateForInsert()

        guard TagsCategoriesType(rawValue: type) != nil else {
            throw StatsCoreDataValidationError.invalidEnumValue
        }
    }


}
