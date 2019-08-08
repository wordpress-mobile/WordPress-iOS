import Foundation
import CoreData


public class FileDownloadsStatsRecordValue: StatsRecordValue {

}

extension StatsFileDownloadsTimeIntervalData: TimeIntervalStatsRecordValueConvertible {
    var recordPeriodType: StatsRecordPeriodType {
        return StatsRecordPeriodType(remoteStatus: period)
    }

    var date: Date {
        return periodEndDate
    }

    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        var downloads: [StatsRecordValue] = fileDownloads.map {
            let value = FileDownloadsStatsRecordValue(context: context)

            value.file = $0.file
            value.downloadCount = Int64($0.downloadCount)

            return value
        }

        let otherAndTotalCount = OtherAndTotalViewsCountStatsRecordValue(context: context,
                                                                         otherCount: otherDownloadsCount,
                                                                         totalCount: totalDownloadsCount)

        downloads.append(otherAndTotalCount)

        return downloads
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let firstRecord = statsRecordValues.first?.statsRecord,
            let period = StatsRecordPeriodType(rawValue: firstRecord.period),
            let date = firstRecord.date,
            let otherAndTotalCount = statsRecordValues.compactMap({ $0 as? OtherAndTotalViewsCountStatsRecordValue }).first
            else {
                return nil
        }

        let fileDownloads: [StatsFileDownload] = statsRecordValues
            .compactMap { $0 as? FileDownloadsStatsRecordValue }
            .compactMap {
                guard
                    let file = $0.file
                    else {
                        return nil
                }

                return StatsFileDownload(file: file, downloadCount: Int($0.downloadCount))
        }

        self = StatsFileDownloadsTimeIntervalData(period: period.statsPeriodUnitValue,
                                                  periodEndDate: date as Date,
                                                  fileDownloads: fileDownloads,
                                                  totalDownloadsCount: Int(otherAndTotalCount.totalCount),
                                                  otherDownloadsCount: Int(otherAndTotalCount.otherCount))
    }

    static var recordType: StatsRecordType {
        return .fileDownloads
    }

}
