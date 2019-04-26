import Foundation
import CoreData


public class TopViewedVideoStatsRecordValue: StatsRecordValue {

    public var postURL: URL? {
        guard let url = postURLString as String? else {
            return nil
        }
        return URL(string: url)
    }

}

extension StatsTopVideosTimeIntervalData: TimeIntervalStatsRecordValueConvertible {
    var recordPeriodType: StatsRecordPeriodType {
        return StatsRecordPeriodType(remoteStatus: period)
    }

    var date: Date {
        return periodEndDate
    }

    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        var mappedVideos: [StatsRecordValue] = videos.map {
            let value = TopViewedVideoStatsRecordValue(context: context)

            value.postID = Int64($0.postID)
            value.postURLString = $0.videoURL?.absoluteString
            value.title = $0.title
            value.playsCount = Int64($0.playsCount)

            return value
        }

        let otherAndTotalCount = OtherAndTotalViewsCountStatsRecordValue(context: context,
                                                                         otherCount: otherPlayCount,
                                                                         totalCount: totalPlaysCount)

        mappedVideos.append(otherAndTotalCount)

        return mappedVideos
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


        let videos: [StatsVideo] = statsRecordValues
            .compactMap { $0 as? TopViewedVideoStatsRecordValue }
            .compactMap {
                guard let title = $0.title else {
                    return nil
                }

                return StatsVideo(postID: Int($0.postID),
                                  title: title,
                                  playsCount: Int($0.playsCount),
                                  videoURL: $0.postURL)
        }

        self = StatsTopVideosTimeIntervalData(period: period.statsPeriodUnitValue,
                                              periodEndDate: date as Date,
                                              videos: videos,
                                              totalPlaysCount: Int(otherAndTotalCount.totalCount),
                                              otherPlayCount: Int(otherAndTotalCount.otherCount))
    }

    static var recordType: StatsRecordType {
        return .videos
    }

}
