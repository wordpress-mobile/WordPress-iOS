import Foundation
import CoreData


public class StreakInsightStatsRecordValue: StatsRecordValue {
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try singleEntryTypeValidation()
    }
}

extension StatsPostingStreakInsight: StatsRecordValueConvertible {
    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        let value = StreakInsightStatsRecordValue(context: context)

        value.currentStreakStart = currentStreakStart as NSDate
        value.currentStreakEnd = currentStreakEnd as NSDate
        value.currentStreakLength = Int64(currentStreakLength)

        value.longestStreakStart = longestStreakStart as NSDate
        value.longestStreakEnd = longestStreakEnd as NSDate
        value.longestStreakLength = Int64(longestStreakLength)

        value.streakData = NSOrderedSet(array: postingEvents.compactMap {
            let value = StreakStatsRecordValue(context: context)

            value.postCount = Int64($0.postCount)
            value.date = $0.date as NSDate

            return value
        })

        return [value]
    }

    init(statsRecordValue: StatsRecordValue) {
        fatalError("This shouldn't be called yet — implementation of StatsRecordValueConvertible is still in progres. This method was added to illustrate intended design, but isn't ready yet.")
    }

    static var recordType: StatsRecordType {
        return .streakInsight
    }


}
