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
        try recordValueSingleValueValidation()
    }
}

extension StatsLastPostInsight: StatsRecordValueConvertible {
    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        let value = LastPostStatsRecordValue(context: context)

        value.commentsCount = Int64(self.commentsCount)
        value.likesCount = Int64(self.likesCount)
        value.publishedDate = self.publishedDate as NSDate
        value.title = self.title
        value.urlString = self.url.absoluteString
        value.viewsCount = Int64(self.viewsCount)
        value.postID = Int64(self.postID)

        return [value]
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let insight = statsRecordValues.first as? LastPostStatsRecordValue,
            let title = insight.title,
            let url = insight.url,
            let publishedDate = insight.publishedDate
        else {
            return nil
        }

        self = StatsLastPostInsight(title: title,
                                    url: url,
                                    publishedDate: publishedDate as Date,
                                    likesCount: Int(insight.likesCount),
                                    commentsCount: Int(insight.commentsCount),
                                    viewsCount: Int(insight.viewsCount),
                                    postID: Int(insight.postID))
    }

    static var recordType: StatsRecordType {
        return .lastPostInsight
    }
}
