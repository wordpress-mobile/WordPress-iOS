import Foundation
import CoreData


public class VisitsSummaryStatsRecordValue: StatsRecordValue {

}

extension VisitsSummaryStatsRecordValue {
    convenience init(managedObjectContext: NSManagedObjectContext, summaryData: StatsSummaryData) {
        self.init(context: managedObjectContext)

        self.viewsCount = Int64(summaryData.viewsCount)
        self.visitorsCount = Int64(summaryData.visitorsCount)
        self.likesCount = Int64(summaryData.likesCount)
        self.commentsCount = Int64(summaryData.commentsCount)
        self.periodStart = summaryData.periodStartDate as NSDate
    }
}

extension StatsSummaryData {
    init?(statsRecordValue: VisitsSummaryStatsRecordValue) {
        guard
            let parent = statsRecordValue.statsRecord,
            let period = StatsRecordPeriodType(rawValue: parent.period),
            let date = statsRecordValue.periodStart
            else {
                return nil
        }

        self = StatsSummaryData(period: period.statsPeriodUnitValue,
                                periodStartDate: date as Date,
                                viewsCount: Int(statsRecordValue.viewsCount),
                                visitorsCount: Int(statsRecordValue.visitorsCount),
                                likesCount: Int(statsRecordValue.likesCount),
                                commentsCount: Int(statsRecordValue.commentsCount))
    }
}

extension StatsSummaryTimeIntervalData: TimeIntervalStatsRecordValueConvertible {
    var recordPeriodType: StatsRecordPeriodType {
        return StatsRecordPeriodType(remoteStatus: period)
    }

    var date: Date {
        return periodEndDate
    }

    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        return summaryData.map { VisitsSummaryStatsRecordValue(managedObjectContext: context, summaryData: $0) }
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let firstParent = statsRecordValues.first?.statsRecord,
            let period = StatsRecordPeriodType(rawValue: firstParent.period),
            let date = firstParent.date
            else {
                return nil
        }

        let summary = statsRecordValues
            .compactMap { return $0 as? VisitsSummaryStatsRecordValue }
            .compactMap { StatsSummaryData(statsRecordValue: $0) }

        self = StatsSummaryTimeIntervalData(period: period.statsPeriodUnitValue,
                                            periodEndDate: date as Date,
                                            summaryData: summary)
    }

    static var recordType: StatsRecordType {
        return .blogVisitsSummary
    }

}
