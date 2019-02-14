import Foundation
import CoreData


public class AllTimeStatsRecordValue: StatsRecordValue {
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try singleEntryTypeValidation()
    }
}
