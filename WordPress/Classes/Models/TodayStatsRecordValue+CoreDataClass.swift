import Foundation
import CoreData


public class TodayStatsRecordValue: StatsRecordValue {
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try singleEntryTypeValidation()
    }
}

extension StatsTodayInsight: StatsRecordValueConvertible {
    func statsRecordValue(in context: NSManagedObjectContext) -> StatsRecordValue {
        let value = TodayStatsRecordValue(context: context)

        value.commentsCount = Int64(self.commentsCount)
        value.likesCount = Int64(self.likesCount)
        value.viewsCount = Int64(self.viewsCount)
        value.visitorsCount = Int64(self.visitorsCount)

        return value
    }

    init(statsRecordValue: StatsRecordValue) {
        // We won't be needing those until later. I added them to protocol to show the intended design
        // but it doesn't make sense to implement it yet.
        fatalError("This shouldn't be called yet — implementation of StatsRecordValueConvertible is still in progres. This method was added to illustrate intended design, but isn't ready yet.")
    }

    static var recordType: StatsRecordType {
        return .today
    }
}
