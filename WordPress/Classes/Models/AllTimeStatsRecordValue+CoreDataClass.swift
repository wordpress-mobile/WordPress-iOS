import Foundation
import CoreData


public class AllTimeStatsRecordValue: StatsRecordValue {
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try recordValueSingleValueValidation()
    }
}

extension StatsAllTimesInsight: StatsRecordValueConvertible {
    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        let value = AllTimeStatsRecordValue(context: context)

        value.postsCount = Int64(self.postsCount)
        value.viewsCount = Int64(self.viewsCount)
        value.visitorsCount = Int64(self.visitorsCount)
        value.bestViewsPerDayCount = Int64(self.bestViewsPerDayCount)
        value.bestViewsDay = self.bestViewsDay as NSDate

        return [value]
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let insight = statsRecordValues.first as? AllTimeStatsRecordValue,
            let bestViewsDay = insight.bestViewsDay
            else {
                return nil
        }

        self = StatsAllTimesInsight(postsCount: Int(insight.postsCount),
                                    viewsCount: Int(insight.viewsCount),
                                    bestViewsDay: bestViewsDay as Date,
                                    visitorsCount: Int(insight.visitorsCount),
                                    bestViewsPerDayCount: Int(insight.bestViewsPerDayCount))
    }

    static var recordType: StatsRecordType {
        return .allTimeStatsInsight
    }
}
