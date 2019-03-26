import Foundation
import CoreData


public class ClicksStatsRecordValue: StatsRecordValue {

    public var clickedURL: URL? {
        guard let url = urlString as String? else {
            return nil
        }
        return URL(string: url)
    }

    public var iconURL: URL? {
        guard let url = iconUrlString as String? else {
            return nil
        }
        return URL(string: url)
    }

}

extension ClicksStatsRecordValue {
    convenience init(managedObjectContext: NSManagedObjectContext, remoteClick: StatsClick) {
        self.init(context: managedObjectContext)

        self.clicksCount = Int64(remoteClick.clicksCount)
        self.label = remoteClick.title
        self.urlString = remoteClick.clickedURL?.absoluteString
        self.iconUrlString = remoteClick.iconURL?.absoluteString

        let children = remoteClick.children.map { ClicksStatsRecordValue(managedObjectContext: managedObjectContext, remoteClick: $0) }

        self.children = NSOrderedSet(array: children)
    }
}

extension StatsClick {
    init?(clicksStatsRecordValue: ClicksStatsRecordValue) {
        guard
            let title = clicksStatsRecordValue.label
            else {
                return nil
        }

        let children = clicksStatsRecordValue.children?.array as? [ClicksStatsRecordValue] ?? []

        self.init(title: title,
                  clicksCount: Int(clicksStatsRecordValue.clicksCount),
                  clickedURL: clicksStatsRecordValue.clickedURL,
                  iconURL: clicksStatsRecordValue.iconURL,
                  children: children.compactMap { StatsClick(clicksStatsRecordValue: $0) })
    }
}


extension StatsTopClicksTimeIntervalData: TimeIntervalStatsRecordValueConvertible {
    var recordPeriodType: StatsRecordPeriodType {
        return StatsRecordPeriodType(remoteStatus: period)
    }

    var date: Date {
        return periodEndDate
    }

    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        var mappedClicks: [StatsRecordValue] = clicks.map { ClicksStatsRecordValue(managedObjectContext: context, remoteClick: $0) }

        let otherAndTotalCount = OtherAndTotalViewsCountStatsRecordValue(context: context,
                                                                         otherCount: otherClicksCount,
                                                                         totalCount: totalClicksCount)

        mappedClicks.append(otherAndTotalCount)

        return mappedClicks
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


        let clicks: [StatsClick] = statsRecordValues
            .compactMap { $0 as? ClicksStatsRecordValue }
            .compactMap { StatsClick(clicksStatsRecordValue: $0) }

        self = StatsTopClicksTimeIntervalData(period: period.statsPeriodUnitValue,
                                              periodEndDate: date as Date,
                                              clicks: clicks,
                                              totalClicksCount: Int(otherAndTotalCount.totalCount),
                                              otherClicksCount: Int(otherAndTotalCount.otherCount))
    }

    static var recordType: StatsRecordType {
        return .clicks
    }

}
