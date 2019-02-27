import Foundation
import CoreData


public class AllTimeStatsRecordValue: StatsRecordValue {
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try singleEntryTypeValidation()
    }
}

extension StatsAllTimesInsight: StatsRecordValueConvertible {
    func statsRecordValue(in context: NSManagedObjectContext) -> StatsRecordValue {
        let value = AllTimeStatsRecordValue(context: context)

        value.postsCount = Int64(self.postsCount)
        value.viewsCount = Int64(self.viewsCount)
        value.visitorsCount = Int64(self.visitorsCount)
        value.bestViewsPerDayCount = Int64(self.bestViewsPerDayCount)
        value.bestViewsDay = self.bestViewsDay as NSDate

        return value
    }

    init(statsRecordValue: StatsRecordValue) {
        // We won't be needing those until later. I added them to protocol to show the intended design
        // but it doesn't make sense to implement it yet.
        fatalError("This shouldn't be called yet — implementation of StatsRecordValueConvertible is still in progres. This method was added to illustrate intended design, but isn't ready yet.")
    }

    static var recordType: StatsRecordType {
        return .allTimeStatsInsight
    }
}
