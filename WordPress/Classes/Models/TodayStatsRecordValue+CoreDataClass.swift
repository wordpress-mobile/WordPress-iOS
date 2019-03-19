import Foundation
import CoreData


public class TodayStatsRecordValue: StatsRecordValue {
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try recordValueSingleValueValidation()
    }
}

extension StatsTodayInsight: StatsRecordValueConvertible {
    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        let value = TodayStatsRecordValue(context: context)

        value.commentsCount = Int64(self.commentsCount)
        value.likesCount = Int64(self.likesCount)
        value.viewsCount = Int64(self.viewsCount)
        value.visitorsCount = Int64(self.visitorsCount)

        return [value]
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let insight = statsRecordValues.first as? TodayStatsRecordValue
            else {
                return nil
        }

        self = StatsTodayInsight(viewsCount: Int(insight.viewsCount),
                                 visitorsCount: Int(insight.visitorsCount),
                                 likesCount: Int(insight.likesCount),
                                 commentsCount: Int(insight.commentsCount))
    }

    static var recordType: StatsRecordType {
        return .today
    }
}
