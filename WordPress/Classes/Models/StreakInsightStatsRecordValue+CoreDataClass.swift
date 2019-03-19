import Foundation
import CoreData


public class StreakInsightStatsRecordValue: StatsRecordValue {
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try recordValueSingleValueValidation()
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

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let insight = statsRecordValues.first as? StreakInsightStatsRecordValue,
            let streakData = insight.streakData?.array as? [StreakStatsRecordValue],

            let currentStreakStart = insight.currentStreakStart,
            let currentStreakEnd = insight.currentStreakEnd,

            let longestStreakStart = insight.longestStreakStart,
            let longestStreakEnd = insight.longestStreakEnd
            else {
                return nil
        }


        self = StatsPostingStreakInsight(currentStreakStart: currentStreakStart as Date,
                                         currentStreakEnd: currentStreakEnd as Date,
                                         currentStreakLength: Int(insight.currentStreakLength),

                                         longestStreakStart: longestStreakStart as Date,
                                         longestStreakEnd: longestStreakEnd as Date,
                                         longestStreakLength: Int(insight.longestStreakLength),

                                         postingEvents: streakData.compactMap {
                                            guard let date = $0.date else {
                                                return nil
                                            }
                                            return PostingStreakEvent(date: date as Date, postCount: Int($0.postCount))
        })
    }

    static var recordType: StatsRecordType {
        return .streakInsight
    }


}
