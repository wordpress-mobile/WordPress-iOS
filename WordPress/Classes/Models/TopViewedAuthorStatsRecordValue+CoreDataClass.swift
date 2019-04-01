import Foundation
import CoreData


public class TopViewedAuthorStatsRecordValue: StatsRecordValue {

    public var avatarURL: URL? {
        guard let url = avatarURLString as String? else {
            return nil
        }
        return URL(string: url)
    }

}

extension StatsTopAuthorsTimeIntervalData: TimeIntervalStatsRecordValueConvertible {

    var recordPeriodType: StatsRecordPeriodType {
        return StatsRecordPeriodType(remoteStatus: period)
    }

    var date: Date {
        return periodEndDate
    }

    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        return topAuthors.compactMap {
            let value = TopViewedAuthorStatsRecordValue(context: context)
            let posts = $0.posts.map { TopViewedPostStatsRecordValue(managedObjectContext: context, remotePost: $0) }

            value.name = $0.name
            value.avatarURLString = $0.iconURL?.absoluteString
            value.viewsCount = Int64($0.viewsCount)
            value.addToPosts(NSOrderedSet(array: posts))

            return value
        }

    }

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let firstParent = statsRecordValues.first?.statsRecord,
            let period = StatsRecordPeriodType(rawValue: firstParent.period),
            let date = firstParent.date
            else {
                return nil
        }

        let authors: [StatsTopAuthor] = statsRecordValues
            .compactMap { return $0 as? TopViewedAuthorStatsRecordValue }
            .compactMap {
                guard
                    let name = $0.name,
                    let posts = $0.posts?.array as? [TopViewedPostStatsRecordValue]
                    else {
                        return nil
                }

                return StatsTopAuthor(name: name,
                                      iconURL: $0.avatarURL,
                                      viewsCount: Int($0.viewsCount),
                                      posts: posts.compactMap { StatsTopPost(topViewedPostStatsRecordValue: $0) })
        }

        self = StatsTopAuthorsTimeIntervalData(period: period.statsPeriodUnitValue,
                                               periodEndDate: date as Date,
                                               topAuthors: authors)
    }

    static var recordType: StatsRecordType {
        return .topViewedAuthor
    }
}
