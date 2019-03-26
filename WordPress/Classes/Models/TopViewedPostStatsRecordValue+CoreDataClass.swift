import Foundation
import CoreData

public enum TopViewsPostType: Int16 {
    case unknown
    case post
    case page
    case homepage

    init(kind: StatsTopPost.Kind) {
        switch kind {
        case .unknown:
            self = .unknown
        case .post:
            self = .post
        case .page:
            self = .page
        case .homepage:
            self = .homepage
        }
    }

    var statsTopPostKind: StatsTopPost.Kind {
        switch self {
        case .unknown:
            return .unknown
        case .post:
            return .post
        case .page:
            return .page
        case .homepage:
            return .homepage
        }
    }
}

public class TopViewedPostStatsRecordValue: StatsRecordValue {
    public var postURL: URL? {
        guard let url = postURLString as String? else {
            return nil
        }
        return URL(string: url)
    }

    public override func validateForInsert() throws {
        try super.validateForInsert()

        guard TopViewsPostType(rawValue: type) != nil else {
            throw StatsCoreDataValidationError.invalidEnumValue
        }
    }
}

extension TopViewedPostStatsRecordValue {
    convenience init(managedObjectContext: NSManagedObjectContext, remotePost: StatsTopPost) {
        self.init(context: managedObjectContext)

        self.postID = Int64(remotePost.postID)
        self.viewsCount = Int64(remotePost.viewsCount)
        self.title = remotePost.title
        self.postURLString = remotePost.postURL?.absoluteString
        self.type = TopViewsPostType(kind: remotePost.kind).rawValue
    }
}

extension StatsTopPost {
    init?(topViewedPostStatsRecordValue: TopViewedPostStatsRecordValue) {
        guard
            let title = topViewedPostStatsRecordValue.title,
            let postType = TopViewsPostType(rawValue: topViewedPostStatsRecordValue.type)
            else {
                return nil
        }

        self = StatsTopPost(title: title,
                            postID: Int(topViewedPostStatsRecordValue.postID),
                            postURL: topViewedPostStatsRecordValue.postURL,
                            viewsCount: Int(topViewedPostStatsRecordValue.viewsCount),
                            kind: postType.statsTopPostKind)
    }
}

extension StatsPublishedPostsTimeIntervalData: TimeIntervalStatsRecordValueConvertible {
    var recordPeriodType: StatsRecordPeriodType {
        return StatsRecordPeriodType(remoteStatus: period)
    }

    var date: Date {
        return periodEndDate
    }

    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        return publishedPosts.compactMap { TopViewedPostStatsRecordValue(managedObjectContext: context, remotePost: $0) }
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let firstParent = statsRecordValues.first?.statsRecord,
            let period = StatsRecordPeriodType(rawValue: firstParent.period),
            let date = firstParent.date
            else {
                return nil
        }

        let posts = statsRecordValues
            .compactMap { return $0 as? TopViewedPostStatsRecordValue }
            .compactMap { StatsTopPost(topViewedPostStatsRecordValue: $0) }

        self = StatsPublishedPostsTimeIntervalData(period: period.statsPeriodUnitValue,
                                                   periodEndDate: date as Date,
                                                   publishedPosts: posts)
    }

    static var recordType: StatsRecordType {
        return .publishedPosts
    }
}

extension StatsTopPostsTimeIntervalData: TimeIntervalStatsRecordValueConvertible {
    var recordPeriodType: StatsRecordPeriodType {
        return StatsRecordPeriodType(remoteStatus: period)
    }

    var date: Date {
        return periodEndDate
    }

    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        var posts: [StatsRecordValue] = topPosts.map { TopViewedPostStatsRecordValue(managedObjectContext: context, remotePost: $0) }

        let otherAndTotalCount = OtherAndTotalViewsCountStatsRecordValue(context: context,
                                                                         otherCount: otherViewsCount,
                                                                         totalCount: totalViewsCount)

        posts.append(otherAndTotalCount)

        return posts
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let firstParent = statsRecordValues.first?.statsRecord,
            let period = StatsRecordPeriodType(rawValue: firstParent.period),
            let date = firstParent.date,
            let otherAndTotalCount = statsRecordValues.compactMap({ $0 as? OtherAndTotalViewsCountStatsRecordValue }).first
            else {
                return nil
        }


        let posts = statsRecordValues
            .compactMap { $0 as? TopViewedPostStatsRecordValue }
            .compactMap { StatsTopPost(topViewedPostStatsRecordValue: $0) }

        self = StatsTopPostsTimeIntervalData(period: period.statsPeriodUnitValue,
                                             periodEndDate: date as Date,
                                             topPosts: posts,
                                             totalViewsCount: Int(otherAndTotalCount.totalCount),
                                             otherViewsCount: Int(otherAndTotalCount.otherCount))
    }

    static var recordType: StatsRecordType {
        return .topViewedPost
    }

}
