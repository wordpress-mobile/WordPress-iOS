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

extension StatsLastPostInsight: StatsRecordValueConvertible {
    func statsRecordValue(in context: NSManagedObjectContext) -> StatsRecordValue {
        let value = LastPostStatsRecordValue(context: context)

        value.commentsCount = Int64(self.commentsCount)
        value.likesCount = Int64(self.likesCount)
        value.publishedDate = self.publishedDate as NSDate
        value.title = self.title
        value.urlString = self.url.absoluteString
        value.viewsCount = Int64(self.viewsCount)

        return value
    }

    init(statsRecordValue: StatsRecordValue) {
        // We won't be needing those until later. I added them to protocol to show the intended design
        // but it doesn't make sense to implement it yet.
        fatalError("This shouldn't be called yet — implementation of StatsRecordValueConvertible is still in progres. This method was added to illustrate intended design, but isn't ready yet.")
    }

    static var recordType: StatsRecordType {
        return .lastPostInsight
    }
}
