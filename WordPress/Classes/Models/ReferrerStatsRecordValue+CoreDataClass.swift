import Foundation
import CoreData


public class ReferrerStatsRecordValue: StatsRecordValue {

    public var referrerURL: URL? {
        guard let url = urlString as String? else {
            return nil
        }
        return URL(string: url)
    }

    public var iconURL: URL? {
        guard let url = iconURLString as String? else {
            return nil
        }
        return URL(string: url)
    }

}

extension ReferrerStatsRecordValue {
    convenience init(managedObjectContext: NSManagedObjectContext, remoteReferrer: StatsReferrer) {
        self.init(context: managedObjectContext)

        self.viewsCount = Int64(remoteReferrer.viewsCount)
        self.label = remoteReferrer.title
        self.urlString = remoteReferrer.url?.absoluteString
        self.iconURLString = remoteReferrer.iconURL?.absoluteString

        let children = remoteReferrer.children.map { ReferrerStatsRecordValue(managedObjectContext: managedObjectContext, remoteReferrer: $0) }
        self.children = NSOrderedSet(array: children)
    }
}

extension StatsReferrer {
    init?(referrerStatsRecordValue: ReferrerStatsRecordValue) {
        guard
            let title = referrerStatsRecordValue.label
            else {
                return nil
        }

        let children = referrerStatsRecordValue.children?.array as? [ReferrerStatsRecordValue] ?? []

        self.init(title: title,
                  viewsCount: Int(referrerStatsRecordValue.viewsCount),
                  url: referrerStatsRecordValue.referrerURL,
                  iconURL: referrerStatsRecordValue.iconURL,
                  children: children.compactMap { StatsReferrer(referrerStatsRecordValue: $0) })
    }
}


extension StatsTopReferrersTimeIntervalData: TimeIntervalStatsRecordValueConvertible {
    var recordPeriodType: StatsRecordPeriodType {
        return StatsRecordPeriodType(remoteStatus: period)
    }

    var date: Date {
        return periodEndDate
    }

    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        var mappedReferrers: [StatsRecordValue] = referrers.map { ReferrerStatsRecordValue(managedObjectContext: context, remoteReferrer: $0) }

        let otherAndTotalCount = OtherAndTotalViewsCountStatsRecordValue(context: context,
                                                                         otherCount: otherReferrerViewsCount,
                                                                         totalCount: totalReferrerViewsCount)

        mappedReferrers.append(otherAndTotalCount)

        return mappedReferrers
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

        let referrers: [StatsReferrer] = statsRecordValues
            .compactMap { $0 as? ReferrerStatsRecordValue }
            .compactMap { StatsReferrer(referrerStatsRecordValue: $0) }

        self = StatsTopReferrersTimeIntervalData(period: period.statsPeriodUnitValue,
                                                 periodEndDate: date as Date,
                                                 referrers: referrers,
                                                 totalReferrerViewsCount: Int(otherAndTotalCount.totalCount),
                                                 otherReferrerViewsCount: Int(otherAndTotalCount.otherCount))
    }

    static var recordType: StatsRecordType {
        return .referrers
    }

}
