import Foundation
import CoreData


public class LastPostStatsRecordValue: StatsRecordValue {
    public var url: URL? {
        guard let url = urlString as String? else {
            return nil
        }
        return URL(string: url)
    }

    public override func validateForInsert() throws {
        try super.validateForInsert()
        try singleEntryTypeValidation()
    }
}
